//
//  SugoRNModule.m
//  sugo-objc-sdk
//
//  Created by lzackx on 2018/1/2.
//  Copyright © 2018年 facebook. All rights reserved.
//

#import "SugoRNModule.h"
#import <Sugo/Sugo.h>

@implementation SugoRNModule

// Expose this module to the React Native bridge
RCT_EXPORT_MODULE(Sugo);


RCT_EXPORT_METHOD(track:(NSString *)eventName props:(NSDictionary *)props) {
    [[Sugo sharedInstance] trackEvent:eventName properties:props];
}

RCT_EXPORT_METHOD(timeEvent:(NSString *)eventName) {
    [[Sugo sharedInstance] timeEvent:eventName];
}

RCT_EXPORT_METHOD(registerSuperProperties:(NSDictionary *)superProps) {
    [[Sugo sharedInstance] registerSuperProperties:superProps];
}

RCT_EXPORT_METHOD(registerSuperPropertiesOnce:(NSDictionary *)superProps) {
    [[Sugo sharedInstance] registerSuperPropertiesOnce:superProps];
}

RCT_EXPORT_METHOD(unregisterSuperProperty:(NSString *)superPropertyName) {
    [[Sugo sharedInstance] unregisterSuperProperty:superPropertyName];
}

RCT_EXPORT_METHOD(clearSuperProperties) {
    [[Sugo sharedInstance] clearSuperProperties];
}

RCT_EXPORT_METHOD(login:(nullable NSString *)userIdKey userIdValue:(nullable NSString *)userIdValue) {
   [[Sugo sharedInstance] trackFirstLoginWith:userIdValue dimension:userIdKey];
}

RCT_EXPORT_METHOD(logout) {
   [[Sugo sharedInstance] untrackFirstLogin];
}

@end
