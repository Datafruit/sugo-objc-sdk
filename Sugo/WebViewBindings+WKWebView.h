//
//  WebViewBindings+WKWebView.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"

@interface WebViewBindings (WKWebView) <WKScriptMessageHandler>

- (void)bindWKWebView:(WKWebView *)webView;
- (void)stopWKWebViewBindings:(WKWebView *)webView;
- (NSString *)jsWKWebViewBindingsSource;
- (NSString *)jsWKWebViewBindingsExcute;

@end
