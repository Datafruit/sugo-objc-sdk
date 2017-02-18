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
            
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewSugo]];
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewTrack]];
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewBindingsSource]];
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewUtils]];
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewReportSource]];
            [webView stringByEvaluatingJavaScriptFromString:[self jsUIWebViewBindingsExcute]];
            
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

- (NSString *)jsUIWebViewSugo
{
    return [self jsSourceOfFileName:@"Sugo"];
}

- (NSString *)jsUIWebViewTrack
{
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.uiWebView.request.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
    if (replacements) {
        for (NSDictionary *replacement in replacements) {
            if ((replacement.allKeys.count <= 0)
                || (((NSString *)replacement.allKeys.firstObject)).length <= 0) {
                continue;
            }
            NSString *key = (NSString *)replacement.allKeys.firstObject;
            NSString *value = (NSString *)replacement[key];
            relativePath = [NSMutableString stringWithFormat:@"%@.replace(/%@/g, %@)",
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
    relativePath = [NSMutableString stringWithFormat:@"%@;", relativePath];
    
    NSMutableString *pn = [[NSMutableString alloc] init];
    NSMutableString *ic = [[NSMutableString alloc] init];
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:nativePath]) {
                pn = info[@"page"];
                ic = info[@"code"];
                break;
            }
        }
    }
    NSMutableString *pageName = [NSMutableString stringWithFormat:@"sugo.page_name = %@;", pn.length>0?pn:@"''"];
    NSMutableString *initCode = [NSMutableString stringWithFormat:@"sugo.init_code = %@;", ic.length>0?ic:@"''"];
    
    NSString *ui = [self jsSourceOfFileName:@"WebViewTrack.UI"];
    
    return [[[relativePath stringByAppendingString:pageName]
             stringByAppendingString:initCode]
            stringByAppendingString:ui];
}

- (NSString *)jsUIWebViewBindingsSource
{
    NSString *vcPath = [NSString stringWithFormat:@"sugo.current_page = '%@::' + window.location.pathname;\n", self.uiVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *ui = [self jsSourceOfFileName:@"WebViewBindings.UI"];
    
    return [[vcPath stringByAppendingString:bindings]
            stringByAppendingString:ui];
}

- (NSString *)jsUIWebViewBindingsExcute
{
    return [self jsSourceOfFileName:@"WebViewBindings.excute"];
}

- (NSString *)jsUIWebViewUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsUIWebViewReportSource
{
    return [self jsSourceOfFileName:@"WebViewReport.UI"];
}

@end










