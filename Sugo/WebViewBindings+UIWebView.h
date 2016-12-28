//
//  WebViewBindings+UIWebView.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"

@interface WebViewBindings (UIWebView)

- (void)bindUIWebView:(UIWebView *)webView;
- (void)stopUIWebViewSwizzle:(UIWebView *)webView;
- (NSString *)jsUIWebViewBindingsSource;
- (NSString *)jsUIWebViewBindingsExcute;

@end
