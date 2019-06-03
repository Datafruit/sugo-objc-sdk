//
//  WebViewBindings.m
//  Sugo
//
//  Created by Zack on 1/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings.h"
#import "WebViewBindings+WebView.h"
#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WKWebView.h"
#import "MPLogger.h"
#import "Sugo.h"
#import "projectMacro.h"

@interface WebViewBindings ()

@end

@implementation WebViewBindings

static WebViewBindings *globalBindings = nil;

+ (instancetype)globalBindings
{
    @synchronized(self) {
        if (globalBindings == nil) {
            globalBindings = [[self alloc] initSingleton];
        }
    }
    return globalBindings;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    @synchronized(self) {
        if (globalBindings == nil) {
            globalBindings = [super allocWithZone:zone];
            return globalBindings;
        }
    }
    return nil;
}

- (instancetype)initSingleton
{
    _mode = Designer;
    _codelessBindings = [[NSMutableArray alloc] init];
    _designerBindings = [[NSMutableArray alloc] init];
    _bindings = [[NSMutableArray alloc] init];
    _stringBindings = [[NSMutableString alloc] init];
    _stringHeats = [[NSMutableString alloc] initWithString:@"{}"];
    self  = [super init];
    
    _uiVcPath = [[NSMutableString alloc] init];
    _wkVcPath = [[NSMutableString alloc] init];
    _isWebViewNeedReload = NO;
    _isWebViewNeedInject = YES;
    _isHeatMapModeOn = false;
    _viewSwizzleRunning = NO;
    
    _uiDidMoveToWindowBlockName = [[NSUUID UUID] UUIDString];
    _uiWebViewJavaScriptInjected = NO;
    _uiWebViewShouldStartLoadBlockName = [[NSUUID UUID] UUIDString];
    _uiWebViewDidStartLoadBlockName = [[NSUUID UUID] UUIDString];
    _uiWebViewDidFinishLoadBlockName = [[NSUUID UUID] UUIDString];
    
    _wkDidMoveToWindowBlockName = [[NSUUID UUID] UUIDString];
    _wkWebViewCurrentJS = [[WKUserScript alloc] init];
    [self addObserver:self
           forKeyPath:@"stringBindings"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"isWebViewNeedReload"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self addObserver:self
           forKeyPath:@"isHeatMapModeOn"
              options:NSKeyValueObservingOptionNew
              context:nil];
    
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"WebViewBindings init exception"
                                   reason:@"this is a singleton, try [WebViewBindings globalBindings]"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc
{
    _mode = Designer;
    [_designerBindings removeAllObjects];
    [_codelessBindings removeAllObjects];
    [_bindings removeAllObjects];
    _stringBindings = nil;
    _isWebViewNeedReload = NO;
    _isWebViewNeedInject = YES;
    
    _stringHeats = nil;
    _isHeatMapModeOn = false;
    
    _uiWebView = nil;
    _uiWebViewDelegate = nil;
    _uiVcPath = nil;
    
    _wkWebView = nil;
    _wkVcPath = nil;
}

- (void)fillBindings
{
    if (self.mode == Designer)
    {
        self.bindings = self.designerBindings;
    } else if (_mode == Codeless)
    {
        self.bindings = self.codelessBindings;
    }
    
    if (self.bindings) {
        NSError *error = nil;
        NSData *jsonBindings = nil;
        @try {
            jsonBindings = [NSJSONSerialization dataWithJSONObject:self.bindings
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
            self.stringBindings = [[NSMutableString alloc] initWithData:jsonBindings
                                                               encoding:NSUTF8StringEncoding];
            MPLogDebug(@"jsonBindings:\n%@\n%@", [jsonBindings debugDescription], self.stringBindings);
        } @catch (NSException *exception) {
            [[Sugo sharedInstance]trackEvent:SDKEXCEPTION properties:[[Sugo sharedInstance]exceptionInfoWithException:exception]];
            MPLogError(@"exception: %@, decoding jsonBindings data: %@ -> %@",
                       exception,
                       [self.bindings debugDescription],
                       jsonBindings);
        }
        if (error) {
            MPLogDebug(@"Failed to translate HTML bindings to String: %@", error);
        }
    }
}

- (void)switchHeatMapMode:(BOOL)mode withData:(NSData *)data
{
    @try {
        self.stringHeats = [[NSMutableString alloc] initWithData:data
                                                           encoding:NSUTF8StringEncoding];
        self.isHeatMapModeOn = mode;
        MPLogDebug(@"stringHeats:\n%@\n", self.stringHeats);
    } @catch (NSException *exception) {
        MPLogError(@"exception: %@, decoding heat map data: %@", exception, data);
    }
}

@end
