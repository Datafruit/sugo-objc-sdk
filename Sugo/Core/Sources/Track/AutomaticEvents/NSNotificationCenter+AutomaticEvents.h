//
//  NSNotificationCenter+AutomaticEvents.h
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNotificationCenter (AutomaticEvents)

- (void)mp_postNotification:(NSNotification *)notification;

- (void)mp_postNotificationName:(NSString *)name
                         object:(nullable id)object
                       userInfo:(nullable NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
