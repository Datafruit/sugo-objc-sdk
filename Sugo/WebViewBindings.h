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
@property (atomic, strong) UIWebView* uiWebView;
@property (atomic, strong) WKWebView* wkWebView;

@property (atomic, strong)NSString* vcPath;
@property (atomic, strong)NSString* stringBindings;

@property BOOL vcSwizzleRunning;
@property BOOL uiWebViewSwizzleRunning;
@property BOOL wkWebViewJavaScriptInjected;
@property (atomic, strong)NSString* vcSwizzleBlockName;
@property (atomic, strong)NSString* uiWebViewSwizzleBlockName;

+ (instancetype)globalBindings;

- (void)fillBindings;

@end
