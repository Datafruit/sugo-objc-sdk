//
//  WebViewBindings.h
//  Sugo
//
//  Created by Zack on 1/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebViewInfoStorage.h"
#import "WebKit/WebKit.h"
#import <JavaScriptCore/JavaScriptCore.h>

typedef NS_ENUM(NSInteger, WebViewBindingsMode)
{
    Designer,
    Codeless,
};

@interface WebViewBindings : NSObject

@property WebViewBindingsMode mode;
@property (atomic, strong) NSMutableArray* codelessBindings;
@property (atomic, strong) NSMutableArray* designerBindings;
@property (atomic, strong) NSMutableArray* bindings;

@property BOOL viewSwizzleRunning;

@property (atomic, strong) NSMutableString* stringBindings;
@property BOOL isWebViewNeedReload;

@property (atomic, weak) UIWebView* uiWebView;
@property (atomic, retain) id <UIWebViewDelegate> uiWebViewDelegate;
@property (atomic, strong) NSString* uiVcPath;
@property (atomic, strong) NSString* uiDidMoveToWindowBlockName;
@property (atomic, strong) NSString* uiRemoveFromSuperviewBlockName;
@property BOOL uiWebViewSwizzleRunning;
@property (atomic, strong) NSString* uiWebViewDidStartLoadBlockName;
@property (atomic, strong) NSString* uiWebViewDidFinishLoadBlockName;
@property BOOL uiWebViewJavaScriptInjected;

@property (atomic, weak) WKWebView* wkWebView;
@property (atomic, strong) NSString* wkVcPath;
@property (atomic, strong) NSString* wkDidMoveToWindowBlockName;
@property (atomic, strong) NSString* wkRemoveFromSuperviewBlockName;
@property BOOL wkWebViewJavaScriptInjected;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSSugo;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSTrack;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSBindingSource;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSBindingExcute;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSUtils;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJSReportSource;

+ (instancetype)globalBindings;

- (void)fillBindings;

@end
