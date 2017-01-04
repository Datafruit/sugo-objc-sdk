//
//  WebViewBindings+WebView.m
//  Sugo
//
//  Created by Zack on 2/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SugoPrivate.h";
#import "WebViewBindings.h"
#import "WebViewBindings+WebView.h"
#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WKWebView.h"
#import "MPSwizzler.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@implementation WebViewBindings (WebView)

- (void)excute
{
    if (!self.viewSwizzleRunning) {
        
        void (^uiDidMoveToWindowBlock)(id, SEL) = ^(id webView, SEL command) {
            UIWebView *uiWebView = (UIWebView *)webView;
            if (!uiWebView) {
                return;
            }
            if (self.uiVcPath.length > 0) {
                return;
            }
            UIResponder *responder = uiWebView;
            while ([responder nextResponder]) {
                responder = responder.nextResponder;
                if ([responder isKindOfClass:[UIViewController class]]) {
                    self.uiVcPath = NSStringFromClass([responder classForCoder]);
                    NSLog(@"UI VC Path: %@", self.uiVcPath);
                    break;
                }
            }
            self.uiWebView = uiWebView;
            [self startUIWebViewBindings:&uiWebView];
        };
        
        void (^uiRemoveFromSuperviewBlock)(id, SEL) = ^(id webView, SEL command) {
            UIWebView *uiWebView = (UIWebView *)webView;
            if (!uiWebView) {
                return;
            }
            self.uiVcPath = nil;
            [self stopUIWebViewBindings:uiWebView];
        };
        
        void (^wkDidMoveToWindowBlock)(id, SEL) = ^(id webView, SEL command) {
            WKWebView *wkWebView = (WKWebView *)webView;
            if (!wkWebView) {
                return;
            }
            if (self.wkVcPath.length > 0) {
                return;
            }
            UIResponder *responder = wkWebView;
            while ([responder nextResponder]) {
                responder = responder.nextResponder;
                if ([responder isKindOfClass:[UIViewController class]]) {
                    self.wkVcPath = NSStringFromClass([responder classForCoder]);
                    NSLog(@"WK VC Path: %@", self.wkVcPath);
                    break;
                }
            }
            self.wkWebView = wkWebView;
            [self startWKWebViewBindings:&wkWebView];
        };

        void (^wkRemoveFromSuperviewBlock)(id, SEL) = ^(id webView, SEL command) {
            WKWebView *wkWebView = (WKWebView *)webView;
            if (!wkWebView) {
                return;
            }
            self.wkVcPath = nil;
            [self stopWKWebViewBindings:wkWebView];
        };
        
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:NSClassFromString(@"UIWebView")
                          withBlock:uiDidMoveToWindowBlock
                              named:self.uiDidMoveToWindowBlockName];
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"removeFromSuperview")
                            onClass:NSClassFromString(@"UIWebView")
                          withBlock:uiRemoveFromSuperviewBlock
                              named:self.uiRemoveFromSuperviewBlockName];
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:NSClassFromString(@"WKWebView")
                          withBlock:wkDidMoveToWindowBlock
                              named:self.wkDidMoveToWindowBlockName];
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"removeFromSuperview")
                            onClass:NSClassFromString(@"WKWebView")
                          withBlock:wkRemoveFromSuperviewBlock
                              named:self.wkRemoveFromSuperviewBlockName];
        self.viewSwizzleRunning = YES;
    }
}

- (void)stop
{
    if (self.viewSwizzleRunning) {
        if (self.uiWebView) {
            [self stopUIWebViewBindings:self.uiWebView];
        }
        if (self.wkWebView) {
            [self stopWKWebViewBindings:self.wkWebView];
        }
        
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                              onClass:NSClassFromString(@"UIWebView")
                                named:self.uiDidMoveToWindowBlockName];
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"removeFromSuperview")
                              onClass:NSClassFromString(@"UIWebView")
                                named:self.uiRemoveFromSuperviewBlockName];
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                              onClass:NSClassFromString(@"WKWebView")
                                named:self.uiDidMoveToWindowBlockName];
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"removeFromSuperview")
                              onClass:NSClassFromString(@"WKWebView")
                                named:self.wkRemoveFromSuperviewBlockName];
        self.viewSwizzleRunning = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    NSLog(@"Object: %@ = \nK: %@ = \nV: %@", object, keyPath, change[NSKeyValueChangeNewKey]);
    if ([keyPath isEqualToString:@"stringBindings"]) {
        if (self.mode == Codeless && [Sugo sharedInstance].isCodelessTesting) {
            self.isWebViewNeedReload = YES;
        }
        if (!self.isWebViewNeedReload) {
            [self stop];
            [self excute];
        }
    }
    
    if ([keyPath isEqualToString:@"isWebViewNeedReload"]) {
        if (!self.isWebViewNeedReload) {
            return;
        }
        if (self.uiWebView) {
            UIWebView *webView = self.uiWebView;
            [self updateUIWebViewBindings:&webView];
            [self.uiWebView performSelectorOnMainThread:@selector(reload)
                                             withObject:nil
                                          waitUntilDone:NO];
        }
        if (self.wkWebView) {
            WKWebView *webView = self.wkWebView;
            [self updateWKWebViewBindings:&webView];
            [self.wkWebView performSelectorOnMainThread:@selector(reload)
                                             withObject:nil
                                          waitUntilDone:NO];
        }
    }
}

@end










