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

@implementation NSNotificationCenter (AutomaticEvents)

- (void)mp_postNotification:(NSNotification *)notification {
    if ([NSNotificationCenter shouldTrackNotificationNamed:notification.name]) {
        [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
    }
    
    [self mp_postNotification:notification];
}

- (void)mp_postNotificationName:(NSString *)name
                         object:(nullable id)object
                       userInfo:(nullable NSDictionary *)info {
    if ([NSNotificationCenter shouldTrackNotificationNamed:name]) {
        [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
    }
    
    [self mp_postNotificationName:name object:object userInfo:info];
}

+ (BOOL)shouldTrackNotificationNamed:(NSString *)name {
    // iOS spams notifications. We're whitelisting for now.
    NSArray *names = @[
                       // UITextField Editing
                       UITextFieldTextDidEndEditingNotification,
                       
                       // UIApplication Lifecycle
                       UIApplicationDidFinishLaunchingNotification,
                       UIApplicationDidEnterBackgroundNotification,
                       UIApplicationDidBecomeActiveNotification ];
    NSSet<NSString *> *whiteListedNotificationNames = [NSSet setWithArray:names];
    return [whiteListedNotificationNames containsObject:name];
}

@end
