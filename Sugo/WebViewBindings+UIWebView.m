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

- (void)startUIWebViewBindings:(UIWebView **)webView
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
        if (![webView isKindOfClass:[UIWebView class]]
            || ((UIWebView *)webView).request.URL.absoluteString.length <= 0
            || ((UIWebView *)webView).isLoading) {
            return;
        }
        if (!self.uiWebViewJavaScriptInjected) {
            JSContext *jsContext = [(UIWebView *)webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            jsContext[@"SugoWebViewJSExport"] = [SugoWebViewJSExport class];
            [((UIWebView *)webView) stringByEvaluatingJavaScriptFromString:[self jsUIWebView]];
            self.uiWebViewJavaScriptInjected = YES;
            MPLogDebug(@"UIWebView Injected");
        }
    };
    
    if (!self.uiWebViewSwizzleRunning) {
        if ((*webView).delegate) {
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                onClass:[(*webView).delegate class]
                              withBlock:uiWebViewDidStartLoadBlock
                                  named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                onClass:[(*webView).delegate class]
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

- (void)updateUIWebViewBindings:(UIWebView **)webView
{
   if (self.uiWebViewSwizzleRunning) {
   }
}

- (NSString *)jsUIWebView
{
    NSString *js = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                           [self jsUIWebViewUtils],
                           [self jsUIWebViewSugoBegin],
                           [self jsUIWebViewVariables],
                           [self jsUIWebViewAPI],
                           [self jsUIWebViewBindings],
                           [self jsUIWebViewReport],
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
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.uiWebView.request.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *rpr = (NSDictionary *)[userDefaults objectForKey:@"HomePath"];
    if (rpr) {
        NSString *homePath = (NSString *)rpr.allKeys.firstObject;
        NSString *replacePath = (NSString *)rpr[homePath];
        relativePath = [NSMutableString stringWithFormat:@"%@.replace('%@', %@)",
                        relativePath,
                        homePath,
                        replacePath.length>0?replacePath:@"''"];
        MPLogDebug(@"relativePath replace Home:\n%@", relativePath);
    }
    if (replacements) {
        for (NSString *replacement in replacements) {
            NSDictionary *r = (NSDictionary *)replacements[replacement];
            NSString *key = (NSString *)r.allKeys.firstObject;
            NSString *value = (NSString *)r[key];
            relativePath = [NSMutableString stringWithFormat:@"%@.replace('%@', %@)",
                            relativePath,
                            key,
                            value.length>0?value:@"''"];
        }
        if (replacements[@"HomePath"]) {
            NSString *key = (NSString *)((NSDictionary *)replacements[@"HomePath"]).allKeys.firstObject;
            NSString *value = (NSString *)((NSDictionary *)replacements[@"HomePath"])[key];
            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key]
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
            nativePath = [NSMutableString
                          stringWithString:[re stringByReplacingMatchesInString:nativePath
                                                                        options:0
                                                                          range:NSMakeRange(0, nativePath.length)
                                                                   withTemplate:value.length>0?value:@""]];
        }
    }
    relativePath = [NSMutableString stringWithFormat:@"%@;\n", relativePath];
    MPLogDebug(@"relativePath:\n%@", relativePath);
    
    NSMutableDictionary *infoObject = [[NSMutableDictionary alloc] initWithDictionary:@{@"code": @"",
                                                                                        @"page_name": @""}];
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:nativePath]) {
                infoObject[@"code"] = info[@"code"];
                infoObject[@"page_name"] = info[@"page_name"];
                break;
            }
        }
    }
    NSData *infoData = [NSJSONSerialization dataWithJSONObject:infoObject
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *infoString = [[NSString alloc] initWithData:infoData
                                                 encoding:NSUTF8StringEncoding];
    
    NSString *initInfo = [NSString stringWithFormat:@"sugo.init = %@;\n", infoString];
    NSString *vcPath = [NSString stringWithFormat:@"sugo.current_page = '%@::' + window.location.pathname;\n", self.uiVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *variables = [self jsSourceOfFileName:@"WebViewVariables"];
    
    return [[[[relativePath stringByAppendingString:initInfo]
              stringByAppendingString:vcPath]
             stringByAppendingString:bindings]
            stringByAppendingString:variables];

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

- (NSString *)jsUIWebViewExcute
{
    return [self jsSourceOfFileName:@"WebViewExcute.Sugo"];
}

- (NSString *)jsUIWebViewSugoEnd
{
    return [self jsSourceOfFileName:@"SugoEnd"];
}

@end










