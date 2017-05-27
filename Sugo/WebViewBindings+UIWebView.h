//
//  WebViewBindings+UIWebView.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"

@interface WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView *)webView;
- (void)stopUIWebViewBindings;
- (void)updateUIWebViewBindings:(UIWebView *)webView;

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

- (void)trackStayEventOfWebView:(UIWebView *)webView;

@end
