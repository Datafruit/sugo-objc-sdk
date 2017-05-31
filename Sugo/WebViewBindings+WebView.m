//
//  WebViewBindings+WebView.m
//  Sugo
//
//  Created by Zack on 2/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "Sugo.h"
#import "SugoPrivate.h"
#import "WebViewBindings.h"
#import "UIViewController+SugoHelpers.h"
#import "WebViewBindings+WebView.h"
#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WKWebView.h"
#import "MPSwizzler.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "MPLogger.h"

@implementation WebViewBindings (WebView)

- (void)excute
{
    if (!self.viewSwizzleRunning) {
        
        void (^uiDidMoveToWindowBlock)(id, SEL) = ^(id webView, SEL command) {
            UIWebView *uiWebView = (UIWebView *)webView;
            if (!uiWebView) {
                return;
            }
            if (self.uiWebView
                && self.uiWebView != uiWebView) {
                self.uiVcPath = nil;
                [self stopUIWebViewBindings];
                if (self.uiWebViewDelegate) {
                    self.uiWebViewDelegate = nil;
                }
            } else if (self.uiWebView) {
                [self trackStayEventOfWebView:self.uiWebView];
                self.uiVcPath = nil;
                [self stopUIWebViewBindings];
                if (self.uiWebViewDelegate) {
                    self.uiWebViewDelegate = nil;
                }
                return;
            }
            self.uiVcPath = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
            self.uiWebView = uiWebView;
            if (self.uiWebView.delegate) {
                self.uiWebViewDelegate = self.uiWebView.delegate;
            }
            [self startUIWebViewBindings:self.uiWebView];
        };
        
        void (^wkDidMoveToWindowBlock)(id, SEL) = ^(id webView, SEL command) {
            WKWebView *wkWebView = (WKWebView *)webView;
            if (!wkWebView) {
                return;
            }
            if (self.wkWebView
                && self.wkWebView != wkWebView) {
                self.wkVcPath = nil;
                [self stopWKWebViewBindings:wkWebView];
            } else if (self.wkWebView) {
                self.wkVcPath = nil;
                [self stopWKWebViewBindings:wkWebView];
                return;
            }
            self.wkVcPath = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
            self.wkWebView = wkWebView;
            [self startWKWebViewBindings:&wkWebView];
        };
        
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:NSClassFromString(@"UIWebView")
                          withBlock:uiDidMoveToWindowBlock
                              named:self.uiDidMoveToWindowBlockName];
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:NSClassFromString(@"WKWebView")
                          withBlock:wkDidMoveToWindowBlock
                              named:self.wkDidMoveToWindowBlockName];
        self.viewSwizzleRunning = YES;
    }
}

- (void)stop
{
    if (self.viewSwizzleRunning) {
        if (self.uiWebView) {
            [self stopUIWebViewBindings];
        }
        if (self.wkWebView) {
            [self stopWKWebViewBindings:self.wkWebView];
        }
        
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                              onClass:NSClassFromString(@"UIWebView")
                                named:self.uiDidMoveToWindowBlockName];
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                              onClass:NSClassFromString(@"WKWebView")
                                named:self.uiDidMoveToWindowBlockName];
        self.viewSwizzleRunning = NO;
    }
}

- (NSString *)jsSourceOfFileName:(NSString *)fileName
{
    NSMutableString *source = [[NSMutableString alloc] init];
    NSBundle *bundle = [NSBundle bundleForClass:[Sugo class]];
    NSString *sourcePath = [bundle pathForResource:fileName ofType:@"js"];
    if (sourcePath) {
        source = [NSMutableString stringWithContentsOfFile:sourcePath
                                                  encoding:NSUTF8StringEncoding
                                                     error:nil];
    }
    return source;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    MPLogDebug(@"Object: %@ = \nK: %@ = \nV: %@", object, keyPath, change[NSKeyValueChangeNewKey]);

    if ([keyPath isEqualToString:@"stringBindings"]) {
        if (self.mode == Codeless) {
            self.isWebViewNeedReload = YES;
        }
        if (!self.isWebViewNeedReload && self.isWebViewNeedInject) {
            [self stop];
            [self excute];
            if (self.isWebViewNeedInject) {
                self.isWebViewNeedInject = NO;
            }
        }
    }
    
    if ([keyPath isEqualToString:@"isWebViewNeedReload"]) {
        if (!self.isWebViewNeedReload) {
            return;
        }
        if (self.uiWebView) {
            [self updateUIWebViewBindings:self.uiWebView];
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
    
    if ([keyPath isEqualToString:@"isHeatMapModeOn"]) {
        self.isWebViewNeedReload = YES;
    }
    
}

@end










