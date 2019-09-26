//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <QuartzCore/QuartzCore.h>
#import "MPApplicationStateSerializer.h"
#import "MPClassDescription.h"
#import "MPLogger.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"
#import "ExceptionUtils.h"
@implementation MPApplicationStateSerializer

{
    MPObjectSerializer *_serializer;
    UIApplication *_application;
}

- (instancetype)initWithApplication:(UIApplication *)application configuration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    @try {
        NSParameterAssert(application != nil);
        NSParameterAssert(configuration != nil);

        self = [super init];
        if (self) {
            _application = application;
            _serializer = [[MPObjectSerializer alloc] initWithConfiguration:configuration objectIdentityProvider:objectIdentityProvider];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return self;
}

- (UIImage *)screenshotImageForKeyWindow
{
    UIImage *image = nil;
    @try {
        UIWindow *window = _application.keyWindow;
        if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 1);
            if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
                MPLogError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return image;
}

- (UIImage *)screenshotImageForWindowAtIndex:(NSUInteger)index
{
    UIImage *image = nil;
    @try {
        UIWindow *window = [self windowAtIndex:index];
        if (window && !CGRectEqualToRect(window.frame, CGRectZero)) {
            UIGraphicsBeginImageContextWithOptions(window.bounds.size, YES, 1);
            if ([window drawViewHierarchyInRect:window.bounds afterScreenUpdates:NO] == NO) {
                MPLogError(@"Unable to get complete screenshot for window at index: %d.", (int)index);
            }
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

    return image;
}

- (NSDictionary *)objectHierarchyForKeyWindow
{
    @try {
        UIWindow *window = _application.keyWindow;
        if (window) {
            return [_serializer serializedObjectsWithRootObject:window];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
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
    @try {
        UIWindow *window = [self windowAtIndex:index];
        if (window) {
            return [_serializer serializedObjectsWithRootObject:window];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return @{};
}

@end
