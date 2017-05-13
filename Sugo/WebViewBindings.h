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
@property (atomic, strong) NSMutableString* stringHeats;
@property BOOL isWebViewNeedReload;
@property BOOL isWebViewNeedInject;
@property BOOL isHeatMapModeOn;

@property (atomic, weak) UIWebView* uiWebView;
@property (atomic, retain) id <UIWebViewDelegate> uiWebViewDelegate;
@property (atomic, strong) NSString* uiVcPath;
@property (atomic, strong) NSString* uiDidMoveToWindowBlockName;
@property BOOL uiWebViewSwizzleRunning;
@property (atomic, strong) NSString* uiWebViewDidStartLoadBlockName;
@property (atomic, strong) NSString* uiWebViewDidFinishLoadBlockName;
@property BOOL uiWebViewJavaScriptInjected;

@property (atomic, weak) WKWebView* wkWebView;
@property (atomic, strong) NSString* wkVcPath;
@property (atomic, strong) NSString* wkDidMoveToWindowBlockName;
@property BOOL wkWebViewJavaScriptInjected;
@property (atomic, strong) WKUserScript *wkWebViewCurrentJS;

+ (instancetype)globalBindings;

- (void)fillBindings;
- (void)switchHeatMapMode:(BOOL)mode withData:(NSData *)data;

@end
