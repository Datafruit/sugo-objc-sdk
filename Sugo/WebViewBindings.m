//
//  WebViewBindings.m
//  Sugo
//
//  Created by Zack on 1/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"
#import "WebViewBindings+UIViewController.h"
#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WKWebView.h"

@interface WebViewBindings ()

@end

@implementation WebViewBindings

+ (instancetype)globalBindings
{
    static WebViewBindings *singleton = nil;
    if (!singleton) {
        singleton = [[self alloc] initSingleton];
    }
    return singleton;
}

- (instancetype)initSingleton
{
    self  = [super init];
    _mode = Designer;
    _vcSwizzleRunning = false;
    _uiWebViewSwizzleRunning = false;
    _wkWebViewJavaScriptInjected = false;
    _vcSwizzleBlockName = [[NSUUID UUID] UUIDString];
    _uiWebViewSwizzleBlockName = [[NSUUID UUID] UUIDString];
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"WebViewBindings init exception"
                                   reason:@"this is a singleton, try [WebViewBindings globalBindings]"
                                 userInfo:nil];
    return nil;
}

- (void)fillBindings
{
    if (_mode == Designer)
    {
        _bindings = _designerBindings;
    } else if (_mode == Codeless)
    {
        _bindings = _codelessBindings;
    }
    
    if (_bindings && [_bindings count] > 0) {
        NSData *jsonBindings = [NSJSONSerialization dataWithJSONObject:_bindings options:NSJSONWritingPrettyPrinted error:nil];
        _stringBindings = [[NSString alloc] initWithData:jsonBindings encoding:NSUTF8StringEncoding];
        [self stop];
        [self excute];
    }
    
}

@end
