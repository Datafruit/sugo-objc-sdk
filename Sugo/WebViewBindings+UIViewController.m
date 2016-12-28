//
//  WebViewBindings+UIViewController.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+UIViewController.h"
#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WKWebView.h"
#import "MPSwizzler.h"


@implementation WebViewBindings (UIViewController)

- (void)excute
{
    if (!self.vcSwizzleRunning) {
        void (^excuteBlock)(id, SEL) = ^(id viewController, SEL command) {

            UIViewController *vc = (UIViewController *)viewController;
            if (vc) {
                for (UIView *subview in vc.view.subviews)
                {
                    if ([subview isKindOfClass:[UIWebView class]])
                    {
                        [self bindUIWebView:(UIWebView *)subview];
                    }
                    else if ([subview isKindOfClass:[WKWebView class]])
                    {
                        [self bindWKWebView:(WKWebView *)subview];
                    }
                }
            }
        };
        
        [MPSwizzler swizzleSelector:@selector(viewDidAppear:)
                            onClass:[UIViewController class]
                          withBlock:excuteBlock
                              named:self.vcSwizzleBlockName];
        self.vcSwizzleRunning = true;
    }
}

- (void)stop
{
    if (self.vcSwizzleRunning) {
        
        if (self.uiWebView) {
            [self stopUIWebViewSwizzle:(UIWebView *) self.uiWebView];
        }
        if (self.wkWebView) {
            [self stopWKWebViewBindings:(WKWebView *) self.wkWebView];
        }
        [MPSwizzler unswizzleSelector:@selector(viewDidAppear:)
                              onClass:[UIViewController class]
                                named:self.vcSwizzleBlockName];
        self.vcSwizzleRunning = false;
    }
}

@end
