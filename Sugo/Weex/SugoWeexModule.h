//
//  SugoWeexModule.h
//  WeexDemo
//
//  Created by lzackx on 2018/1/2.
//  Copyright © 2018年 taobao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WeexSDK/WeexSDK.h>

@interface SugoWeexModule : NSObject <WXModuleProtocol>

WX_EXPORT_METHOD_SYNC(@selector(track:props:))
WX_EXPORT_METHOD_SYNC(@selector(timeEvent:))
WX_EXPORT_METHOD_SYNC(@selector(registerSuperProperties:))
WX_EXPORT_METHOD_SYNC(@selector(registerSuperPropertiesOnce:))
WX_EXPORT_METHOD_SYNC(@selector(unregisterSuperProperty:))
WX_EXPORT_METHOD_SYNC(@selector(getSuperProperties:))
WX_EXPORT_METHOD_SYNC(@selector(clearSuperProperties))
WX_EXPORT_METHOD_SYNC(@selector(login:userIdValue:))
WX_EXPORT_METHOD_SYNC(@selector(logout))

@end
