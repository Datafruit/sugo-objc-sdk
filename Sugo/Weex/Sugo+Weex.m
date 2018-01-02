//
//  Sugo+Weex.m
//  WeexDemo
//
//  Created by lzackx on 2018/1/2.
//  Copyright © 2018年 taobao. All rights reserved.
//

#import "Sugo+Weex.h"
#import "SugoWeexModule.h"
#import <WeexSDK/WeexSDK.h>

@implementation Sugo (Weex)

- (void)registerModule {
    [WXSDKEngine registerModule:@"sugo" withClass:[SugoWeexModule class]];
}

@end
