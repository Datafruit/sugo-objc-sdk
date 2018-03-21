//
//  SugoHelper.h
//  SugoHelper
//
//  Created by lzackx on 2018/3/20.
//  Copyright © 2018年 lzackx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SugoHelper : NSObject

// MARK: Init
+ (void)initializeEnable:(BOOL)enable
               projectID:(NSString *)projectID
                   token:(NSString *)token
              bindingURL:(NSString *)binding
           collectionURL:(NSString *)collection
             codelessURL:(NSString *)codeless;

+ (BOOL)hasSugoInitialized;
+ (BOOL)handleURL:(NSURL *)url;
+ (void)connectToCodelessViaURL:(NSURL *)url;
+ (void)requestForHeatMapViaURL:(NSURL *)url;
+ (void)setEnableLogging:(BOOL)enableLogging;
+ (void)setFlushInterval:(NSUInteger)interval;
+ (void)setCacheInterval:(double)interval;

// MARK: Track
+ (void)trackEvent:(NSString *)event;
+ (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventID:(NSString *)eventID eventName:(NSString *)eventName;
+ (void)trackEventID:(NSString *)eventID eventName:(NSString *)eventName properties:(NSDictionary *)properties;
+ (void)timeEvent:(NSString *)event;
+ (void)clearTimedEvents;

// MARK: Super Properties
+ (void)registerSuperProperties:(NSDictionary *)properties;
+ (void)registerSuperPropertiesOnce:(NSDictionary *)properties;
+ (void)registerSuperPropertiesOnce:(NSDictionary *)properties defaultValue:(id)defaultValue;
+ (void)unregisterSuperProperty:(NSString *)propertyName;
+ (NSDictionary *)currentSuperProperties;
+ (void)clearSuperProperties;

// MARK: Deprecated
+ (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

@end
