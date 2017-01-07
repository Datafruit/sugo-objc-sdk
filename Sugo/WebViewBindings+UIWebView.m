//
//  WebViewBindings+UIWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WebView.h"
#import "WebViewJSExport.h"
#import "MPSwizzler.h"


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
            [jsContext evaluateScript:[self jsUIWebViewTrack]];
            [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
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
//        if ((*webView).delegate) {
//            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
//                                  onClass:[(*webView).delegate class]
//                                    named:self.uiWebViewDidStartLoadBlockName];
//            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
//                                  onClass:[(*webView).delegate class]
//                                    named:self.uiWebViewDidFinishLoadBlockName];
//        }
        self.uiWebViewJavaScriptInjected = NO;
        self.uiWebViewSwizzleRunning = NO;
        self.uiWebView = nil;
    }
}

- (void)updateUIWebViewBindings:(UIWebView **)webView
{
    if (self.uiWebViewSwizzleRunning) {
        JSContext *jsContext = [(*webView) valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        WebViewJSExport *jsExport = [[WebViewJSExport alloc] init];
        jsContext[@"WebViewJSExport"] = jsExport;
        [jsContext evaluateScript:[self jsUIWebViewTrack]];
        [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
        [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
    }
}

- (NSString *)jsUIWebViewTrack
{
    return [self jsSourceOfFileName:@"UIWebViewTrack"];
}

- (NSString *)jsUIWebViewBindingsSource
{
    
    NSString *part1 = [self jsSourceOfFileName:@"WebViewBindings.1"];
    NSString *vcPath = [NSString stringWithFormat:@"sugo_bindings.current_page = '%@::' + window.location.pathname;\n", self.uiVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo_bindings.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *part2 = [self jsSourceOfFileName:@"WebViewBindings.2"];
    
    return [[[part1 stringByAppendingString:vcPath]
             stringByAppendingString:bindings]
            stringByAppendingString:part2];
}

- (NSString *)jsUIWebViewBindingsExcute
{
    return [self jsSourceOfFileName:@"WebViewBindings.excute"];
}

@end










