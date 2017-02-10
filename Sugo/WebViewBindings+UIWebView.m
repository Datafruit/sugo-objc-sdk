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
#import "WebViewJSExport.h"
#import "MPSwizzler.h"
#import "SugoPrivate.h"


@implementation WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView **)webView
{
    void (^uiWebViewDidStartLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        if (self.uiWebViewJavaScriptInjected) {
            self.uiWebViewJavaScriptInjected = NO;
            NSLog(@"UIWebView Uninjected");
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
            jsContext[@"WebViewJSExport"] = [WebViewJSExport class];
            [jsContext evaluateScript:[self jsUISugo]];
            [jsContext evaluateScript:[self jsUIWebViewTrack]];
            [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
            [jsContext evaluateScript:[self jsUIUtils]];
            [jsContext evaluateScript:[self jsUIWebViewReportSource]];
            [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
            self.uiWebViewJavaScriptInjected = YES;
            NSLog(@"UIWebView Injected");
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

- (void)stopUIWebViewBindings:(UIWebView *)webView
{
    if (self.uiWebViewSwizzleRunning) {
//        if (webView && webView.delegate) {
//            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
//                                  onClass:[webView.delegate class]
//                                    named:self.uiWebViewDidStartLoadBlockName];
//            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
//                                  onClass:[webView.delegate class]
//                                    named:self.uiWebViewDidFinishLoadBlockName];
//        }
        self.uiWebViewJavaScriptInjected = NO;
        self.uiWebViewSwizzleRunning = NO;
        self.uiWebView = nil;
    }
}

- (void)updateUIWebViewBindings:(UIWebView **)webView
{
//    if (self.uiWebViewSwizzleRunning) {
//        JSContext *jsContext = [(*webView) valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//        jsContext[@"WebViewJSExport"] = [WebViewJSExport class];
//        [jsContext evaluateScript:[self jsUISugo]];
//        [jsContext evaluateScript:[self jsUIWebViewTrack]];
//        [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
//        [jsContext evaluateScript:[self jsUIUtils]];
//        [jsContext evaluateScript:[self jsUIWebViewReportSource]];
//        [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
//    }
}

- (NSString *)jsUISugo
{
    return [self jsSourceOfFileName:@"Sugo"];
}

- (NSString *)jsUIWebViewTrack
{
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.uiWebView.request.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacement = [Sugo loadConfigurationPropertyListWithName:@"SugoResourcesPathReplacement"];
    if (replacement) {
        for (NSString *key in replacement.allKeys) {
            relativePath = [NSMutableString stringWithFormat:@"%@.replace(/%@/g, %@)",
                            relativePath,
                            key.length>0?key:@" ",
                            ((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@"''"];
            
            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key.length>0?key:@""]
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
            nativePath =  [NSMutableString
                           stringWithString:[re stringByReplacingMatchesInString:nativePath
                                                                         options:0
                                                                           range:NSMakeRange(0, nativePath.length)
                                                                    withTemplate:((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@""]];
            
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

- (NSString *)jsUIUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsUIWebViewReportSource
{
    return [self jsSourceOfFileName:@"WebViewReport.UI"];
}

@end










