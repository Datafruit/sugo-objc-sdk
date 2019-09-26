//
//  NSNotificationCenter+AutomaticEvents.m
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "NSNotificationCenter+AutomaticEvents.h"
#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#import "ExceptionUtils.h"
@implementation NSNotificationCenter (AutomaticEvents)

- (void)mp_postNotification:(NSNotification *)notification {
    @try {
        if ([NSNotificationCenter shouldTrackNotificationNamed:notification.name]) {
            [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
        }
        
        [self mp_postNotification:notification];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (void)mp_postNotificationName:(NSString *)name
                         object:(nullable id)object
                       userInfo:(nullable NSDictionary *)info {
    @try {
        if ([NSNotificationCenter shouldTrackNotificationNamed:name]) {
            [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
        }
    
        [self mp_postNotificationName:name object:object userInfo:info];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

+ (BOOL)shouldTrackNotificationNamed:(NSString *)name {
    // iOS spams notifications. We're whitelisting for now.
    @try {
        NSArray *names = @[
                           // UITextField Editing
                           UITextFieldTextDidEndEditingNotification,
                           
                           // UIApplication Lifecycle
                           UIApplicationDidFinishLaunchingNotification,
                           UIApplicationDidEnterBackgroundNotification,
                           UIApplicationDidBecomeActiveNotification ];
        NSSet<NSString *> *whiteListedNotificationNames = [NSSet setWithArray:names];
        return [whiteListedNotificationNames containsObject:name];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

@end
