//
//  WebViewBindings+UIWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WebView.h"
#import "SugoPageInfos.h"
#import "SugoWebViewJSExport.h"
#import "MPSwizzler.h"
#import "SugoPrivate.h"
#import "MPLogger.h"


@implementation WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView *)webView
{
    void (^uiWebViewDidStartLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        JSContext *jsContext = [(UIWebView *)webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        jsContext[@"SugoWebViewJSExport"] = [SugoWebViewJSExport class];
        if (self.uiWebViewJavaScriptInjected) {
            self.uiWebViewJavaScriptInjected = NO;
            MPLogDebug(@"UIWebView Uninjected");
        }
    };
    
    void (^uiWebViewDidFinishLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        UIWebView *uiWebView = (UIWebView *)webView;
        if (uiWebView.request.URL.absoluteString.length <= 0
            || uiWebView.isLoading) {
            return;
        }
        if (!self.uiWebViewJavaScriptInjected) {
            JSContext *jsContext = [uiWebView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            jsContext[@"SugoWebViewJSExport"] = [SugoWebViewJSExport class];
            [uiWebView stringByEvaluatingJavaScriptFromString:[self jsUIWebView]];
            self.uiWebViewJavaScriptInjected = YES;
            MPLogDebug(@"UIWebView Injected");
        }
    };
    
    UIWebView *uiWebView = (UIWebView *)webView;
    if (!self.uiWebViewSwizzleRunning) {
        if (uiWebView.delegate) {
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                onClass:[uiWebView.delegate class]
                              withBlock:uiWebViewDidStartLoadBlock
                                  named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                onClass:[uiWebView.delegate class]
                              withBlock:uiWebViewDidFinishLoadBlock
                                  named:self.uiWebViewDidFinishLoadBlockName];
            self.uiWebViewSwizzleRunning = YES;
        }
    }
}

- (void)stopUIWebViewBindings
{
    if (self.uiWebViewSwizzleRunning) {
        if (self.uiWebViewDelegate) {
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                  onClass:[self.uiWebViewDelegate class]
                                    named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                  onClass:[self.uiWebViewDelegate class]
                                    named:self.uiWebViewDidFinishLoadBlockName];
        }
        self.uiWebViewJavaScriptInjected = NO;
        self.uiWebViewSwizzleRunning = NO;
        self.uiWebView = nil;
    }
}

- (void)updateUIWebViewBindings:(UIWebView *)webView
{
   if (self.uiWebViewSwizzleRunning) {
   }
}

- (NSString *)jsUIWebView
{
    NSString *js = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                    [self jsUIWebViewUtils],
                    [self jsUIWebViewSugoBegin],
                    [self jsUIWebViewVariables],
                    [self jsUIWebViewAPI],
                    [self jsUIWebViewBindings],
                    [self jsUIWebViewReport],
                    [self jsUIHeatMap],
                    [self jsUIWebViewExcute],
                    [self jsUIWebViewSugoEnd]];
    MPLogDebug(@"UIWebView JavaScript:\n%@", js);
    return js;
}

- (NSString *)jsUIWebViewUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsUIWebViewSugoBegin
{
    return [self jsSourceOfFileName:@"SugoBegin"];
}

- (NSString *)jsUIWebViewVariables
{
    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *rpr = (NSDictionary *)[userDefaults objectForKey:@"HomePath"];
    NSString *homePathKey = [[NSString alloc] init];
    NSString *homePathValue = [[NSString alloc] init];
    if (rpr) {
        homePathKey = (NSString *)rpr.allKeys.firstObject;
        homePathValue = (NSString *)rpr[homePathKey];
    }
    NSMutableArray *res = [[NSMutableArray alloc] init];
    NSMutableString *resString = nil;
    if (replacements) {
        for (NSString *replacement in replacements) {
            NSDictionary *r = (NSDictionary *)replacements[replacement];
            NSString *key = (NSString *)r.allKeys.firstObject;
            NSString *value = (NSString *)r[key];
            [res addObject:@{key: value}];
        }
        NSError *error = nil;
        NSData *resJSON = nil;
        @try {
            resJSON = [NSJSONSerialization dataWithJSONObject:res
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&error];
            resString = [[NSMutableString alloc] initWithData:resJSON
                                                     encoding:NSUTF8StringEncoding];
        } @catch (NSException *exception) {
            MPLogError(@"exception: %@, decoding resJSON data: %@ -> %@",
                       exception,
                       resJSON,
                       resString);
        }
    }
    NSMutableString *infosString = nil;
    if ([SugoPageInfos global].infos.count > 0) {
        NSError *error = nil;
        NSData *infosJSON = nil;
        @try {
            infosJSON = [NSJSONSerialization dataWithJSONObject:[SugoPageInfos global].infos
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&error];
            infosString = [[NSMutableString alloc] initWithData:infosJSON
                                                     encoding:NSUTF8StringEncoding];
        } @catch (NSException *exception) {
            MPLogError(@"exception: %@, decoding resJSON data: %@ -> %@",
                       exception,
                       infosJSON,
                       infosString);
        }
    }
    NSString *vcPath = [NSString stringWithFormat:@"sugo.view_controller = '%@';\n", self.uiVcPath];
    NSString *homePath = [NSString stringWithFormat:@"sugo.home_path = '%@';\n", homePathKey];
    NSString *homePathReplacement = [NSString stringWithFormat:@"sugo.home_path_replacement = '%@';\n", homePathValue];
    NSString *regularExpressions = [NSString stringWithFormat:@"sugo.regular_expressions = %@;\n", resString?resString:@"[]"];
    NSString *pageInfos = [NSString stringWithFormat:@"sugo.page_infos = %@;\n", infosString?infosString:@"[]"];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *canTrackWebPage = [NSString stringWithFormat:@"sugo.can_track_web_page = %@;\n", SugoCanTrackWebPage?@"true":@"false"];
    NSString *canShowHeatMap = [NSString stringWithFormat:@"sugo.can_show_heat_map = %@;\n", self.isHeatMapModeOn?@"true":@"false"];
    NSString *heats = [NSString stringWithFormat:@"sugo.h5_heats = %@;\n", self.stringHeats];
    NSString *vars = [self jsSourceOfFileName:@"WebViewVariables"];
    
    NSString *variables = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@%@%@",
                           vcPath,
                           homePath,
                           homePathReplacement,
                           regularExpressions,
                           pageInfos,
                           bindings,
                           canTrackWebPage,
                           canShowHeatMap,
                           heats,
                           vars];
    
    return variables;
}

- (NSString *)jsUIWebViewAPI
{
    NSString *api = [self jsSourceOfFileName:@"WebViewAPI.UI"];
    
    return api;
}

- (NSString *)jsUIWebViewBindings
{
    return [self jsSourceOfFileName:@"WebViewBindings.UI"];
}

- (NSString *)jsUIWebViewReport
{
    return [self jsSourceOfFileName:@"WebViewReport.UI"];
}

- (NSString *)jsUIHeatMap
{
    return [self jsSourceOfFileName:@"WebViewHeatmap"];
}

- (NSString *)jsUIWebViewExcute
{
    return [self jsSourceOfFileName:@"WebViewExcute.Sugo"];
}

- (NSString *)jsUIWebViewSugoEnd
{
    return [self jsSourceOfFileName:@"SugoEnd"];
}

@end










