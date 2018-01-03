//
//  SugoWeexModule.m
//  WeexDemo
//
//  Created by lzackx on 2018/1/2.
//  Copyright © 2018年 taobao. All rights reserved.
//

#import "SugoWeexModule.h"
#import "Sugo.h"

@implementation SugoWeexModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(track:props:))
- (void)track:(NSString *)eventName props:(NSDictionary *)props {
    [[Sugo sharedInstance] trackEvent:eventName properties:props];
}

WX_EXPORT_METHOD(@selector(timeEvent:))
- (void)timeEvent:(NSString *)eventName {
    [[Sugo sharedInstance] timeEvent:eventName];
}

WX_EXPORT_METHOD(@selector(registerSuperProperties:))
- (void)registerSuperProperties:(NSDictionary *)superProps {
    [[Sugo sharedInstance] registerSuperProperties:superProps];
}

WX_EXPORT_METHOD(@selector(registerSuperPropertiesOnce:))
- (void)registerSuperPropertiesOnce:(NSDictionary *)superProps {
    [[Sugo sharedInstance] registerSuperPropertiesOnce:superProps];
}

WX_EXPORT_METHOD(@selector(unregisterSuperProperty:))
- (void)unregisterSuperProperty:(NSString *)superPropertyName {
    [[Sugo sharedInstance] unregisterSuperProperty:superPropertyName];
}

WX_EXPORT_METHOD(@selector(getSuperProperties:))
- (void)getSuperProperties:(WXModuleCallback)callback {
    callback([[Sugo sharedInstance] currentSuperProperties]);
}

WX_EXPORT_METHOD(@selector(clearSuperProperties))
- (void)clearSuperProperties {
    [[Sugo sharedInstance] clearSuperProperties];
}

WX_EXPORT_METHOD(@selector(login:dimension:))
- (void)login:(nullable NSString *)userIdKey dimension:(nullable NSString *)userIdValue {
   [[Sugo sharedInstance] trackFirstLoginWith:userIdValue dimension:userIdKey];
}

WX_EXPORT_METHOD(@selector(logout))
- (void)logout {
   [[Sugo sharedInstance] untrackFirstLogin];
}

@end
