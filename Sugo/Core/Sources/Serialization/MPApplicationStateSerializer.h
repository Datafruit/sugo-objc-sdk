//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <UIKit/UIKit.h>

@class MPObjectSerializerConfig;
@class MPObjectIdentityProvider;

@interface MPApplicationStateSerializer : NSObject

- (instancetype)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider;

- (UIImage *)screenshotImageForKeyWindow;
- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index;

- (NSDictionary *)objectHierarchyForKeyWindow;
- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index;

@end
