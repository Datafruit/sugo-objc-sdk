//
//  WebViewBindings+UIWebView.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"

@interface WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView **)webView;
- (void)stopUIWebViewBindings:(UIWebView *)webView;
- (void)updateUIWebViewBindings:(UIWebView **)webView;
- (NSString *)jsUIWebViewTrack;
- (NSString *)jsUIWebViewBindingsSource;
- (NSString *)jsUIWebViewBindingsExcute;

@end
