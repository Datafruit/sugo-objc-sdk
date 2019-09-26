//
//  UIViewController+AutomaticEvents.m
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "UIViewController+AutomaticEvents.h"
#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#import "ExceptionUtils.h"

@implementation UIViewController (AutomaticEvents)

- (void)mp_viewDidAppear:(BOOL)animated {
    @try {
        if ([self shouldTrackClass:self.class]) {
            [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
        }
        [self mp_viewDidAppear:animated];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (BOOL)shouldTrackClass:(Class)aClass {
    @try {
        static NSSet *blacklistedClasses = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSArray *blacklistedClassNames = @[ @"UICompatibilityInputViewController",
                                                @"UIKeyboardCandidateGridCollectionViewController",
                                                @"UIInputWindowController",
                                                @"UICompatibilityInputViewController" ];
            NSMutableSet *transformedClasses = [NSMutableSet setWithCapacity:blacklistedClassNames.count];
            for (NSString *className in blacklistedClassNames) {
                [transformedClasses addObject:NSClassFromString(className)];
            }
            blacklistedClasses = [transformedClasses copy];
        });
        
        return ![blacklistedClasses containsObject:aClass];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return NO;
    }
}

@end
