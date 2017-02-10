//
//  UIApplication+AutomaticEvents.m
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "UIApplication+AutomaticEvents.h"
#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"

@implementation UIApplication (AutomaticEvents)

- (BOOL)mp_sendAction:(SEL)action to:(id)to from:(id)from forEvent:(UIEvent *)event {
    [[Sugo sharedAutomatedInstance] trackEvent:kAutomaticEventName];
    return [self mp_sendAction:action to:to from:from forEvent:event];
}

@end
