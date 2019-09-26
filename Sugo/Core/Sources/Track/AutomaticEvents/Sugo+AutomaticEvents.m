//
//  Sugo+AutomaticEvents.m
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "Sugo+AutomaticEvents.h"
#import "UIApplication+AutomaticEvents.h"
#import "UIViewController+AutomaticEvents.h"
#import "NSNotificationCenter+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#import "MPSwizzle.h"
#import "MPLogger.h"
#import "ExceptionUtils.h"

@implementation Sugo (AutomaticEvents)

static Sugo *gSharedAutomatedInstance = nil;
+ (instancetype)sharedAutomatedInstance {
    return gSharedAutomatedInstance;
}

+ (void)setSharedAutomatedInstance:(Sugo *)instance {
    gSharedAutomatedInstance = instance;
    [self addSwizzles];
}

+ (void)addSwizzles {
    @try {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            @try {
                NSError *error = NULL;
                
                // Navigation
                [UIViewController mp_swizzleMethod:@selector(viewDidAppear:)
                                        withMethod:@selector(mp_viewDidAppear:)
                                             error:&error];
                if (error) {
                    MPLogError(@"Failed to swizzle viewDidAppear: on UIViewController. Details: %@", error);
                    error = NULL;
                }
                
                // Actions & Events
                [UIApplication mp_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                                     withMethod:@selector(mp_sendAction:to:from:forEvent:)
                                          error:&error];
                if (error) {
                    MPLogError(@"Failed to swizzle sendAction:to:from:forEvent: on UIAppplication. Details: %@", error);
                    error = NULL;
                }
                
                // Notifications
                [NSNotificationCenter mp_swizzleMethod:@selector(postNotification:)
                                            withMethod:@selector(mp_postNotification:)
                                                 error:&error];
                if (error) {
                    MPLogError(@"Failed to swizzle postNotification: on NSNotificationCenter. Details: %@", error);
                    error = NULL;
                }

                [NSNotificationCenter mp_swizzleMethod:@selector(postNotificationName:object:userInfo:)
                                            withMethod:@selector(mp_postNotificationName:object:userInfo:)
                                                 error:&error];
                if (error) {
                    MPLogError(@"Failed to swizzle postNotificationName:object:userInfo: on NSNotificationCenter. Details: %@", error);
                    error = NULL;
                }
            } @catch (NSException *exception) {
                [ExceptionUtils exceptionToNetWork:exception];
            }
        });
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

}

@end
