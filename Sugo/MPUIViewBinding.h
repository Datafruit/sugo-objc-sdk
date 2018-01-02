//
//  MPUIViewBinding.h
//  HelloSugo
//
//  Created by Amanda Canyon on 8/4/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPEventBinding.h"

@interface MPUIViewBinding : MPEventBinding

@property (nonatomic, readonly) UIControlEvents controlEvent;
@property (nonatomic, readonly) UIControlEvents verifyEvent;

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
               withControlEvent:(UIControlEvents)controlEvent
                 andVerifyEvent:(UIControlEvents)verifyEvent
                     attributes:(Attributes *)attributes;

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                     attributes:(Attributes *)attributes;

@end
