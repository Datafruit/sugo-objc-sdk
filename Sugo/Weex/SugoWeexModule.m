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

WX_EXPORT_METHOD_SYNC(@selector(track:props:))
- (void)track:(NSString *)eventName props:(NSDictionary *)props {
    [SugoHelper trackEvent:eventName properties:props];
}

WX_EXPORT_METHOD_SYNC(@selector(timeEvent:))
- (void)timeEvent:(NSString *)eventName {
    [SugoHelper timeEvent:eventName];
}

WX_EXPORT_METHOD_SYNC(@selector(registerSuperProperties:))
- (void)registerSuperProperties:(NSDictionary *)superProps {
    [SugoHelper registerSuperProperties:superProps];
}

WX_EXPORT_METHOD_SYNC(@selector(registerSuperPropertiesOnce:))
- (void)registerSuperPropertiesOnce:(NSDictionary *)superProps {
    [SugoHelper registerSuperPropertiesOnce:superProps];
}

WX_EXPORT_METHOD_SYNC(@selector(unregisterSuperProperty:))
- (void)unregisterSuperProperty:(NSString *)superPropertyName {
    [SugoHelper unregisterSuperProperty:superPropertyName];
}

WX_EXPORT_METHOD_SYNC(@selector(getSuperProperties:))
- (void)getSuperProperties:(WXModuleCallback)callback {
    callback([SugoHelper currentSuperProperties]);
}

WX_EXPORT_METHOD_SYNC(@selector(clearSuperProperties))
- (void)clearSuperProperties {
    [SugoHelper clearSuperProperties];
}

WX_EXPORT_METHOD_SYNC(@selector(login:userIdValue:))
- (void)login:(nullable NSString *)userIdKey userIdValue:(nullable NSString *)userIdValue {
   [SugoHelper trackFirstLoginWith:userIdValue dimension:userIdKey];
}

WX_EXPORT_METHOD_SYNC(@selector(logout))
- (void)logout {
   [SugoHelper untrackFirstLogin];
}

@end
