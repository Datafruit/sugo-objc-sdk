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

- (void)track:(NSString *)eventName props:(NSDictionary *)props {
    [[Sugo sharedInstance] trackEvent:eventName properties:props];
}

- (void)timeEvent:(NSString *)eventName {
    [[Sugo sharedInstance] timeEvent:eventName];
}

- (void)registerSuperProperties:(NSDictionary *)superProps {
    [[Sugo sharedInstance] registerSuperProperties:superProps];
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)superProps {
    [[Sugo sharedInstance] registerSuperPropertiesOnce:superProps];
}

- (void)unregisterSuperProperty:(NSString *)superPropertyName {
    [[Sugo sharedInstance] unregisterSuperProperty:superPropertyName];
}

- (void)getSuperProperties:(WXModuleCallback)callback {
    callback([[Sugo sharedInstance] currentSuperProperties]);
}

- (void)clearSuperProperties {
    [[Sugo sharedInstance] clearSuperProperties];
}

- (void)login:(nullable NSString *)userIdKey userIdValue:(nullable NSString *)userIdValue {
   [[Sugo sharedInstance] trackFirstLoginWith:userIdValue dimension:userIdKey];
}

- (void)logout {
   [[Sugo sharedInstance] untrackFirstLogin];
}

@end
