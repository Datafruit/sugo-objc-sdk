//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <QuartzCore/QuartzCore.h>
#import "MPApplicationStateSerializer.h"
#import "MPClassDescription.h"
#import "MPLogger.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"

@implementation MPApplicationStateSerializer

{
    MPObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    NSParameterAssert(application != nil);
    NSParameterAssert(configuration != nil);

    self = [super init];
    if (self) {
        _application = application;
        _serializer = [[MPObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
    }

    return self;
}

- (UIImage *)screenshotImageForKeyWindow
{
    UIImage *image = nil;
    
    UIWindow *window = _application.keyWindow;
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 1);
        if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
            MPLogError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index
{
    UIImage *image = nil;

    UIWindow *window = [self windowAtIndex:index];
    if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
        UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 1);
        if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
            MPLogError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
        }
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

- (NSDictionary *)objectHierarchyForKeyWindow
{
    UIWindow *window = _application.keyWindow;
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }
    
    return @{};
}

- (UIWindow *)windowAtIndex:(NSUInteger)index
{
    NSParameterAssert(index < _application.windows.count);
    return _application.windows[index];
}

- (NSDictionary *)objectHierarchyForWindowAtIndex:(NSUInteger)index
{
    UIWindow *window = [self windowAtIndex:index];
    if (window) {
        return [_serializer serializedObjectsWithRootObject:window];
    }

    return @{};
}

@end
