//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <UIKit/UIKit.h>

@class MPObjectSerializerConfig;
@class MPObjectIdentityProvider;

@interface MPApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index;

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index;

@end
