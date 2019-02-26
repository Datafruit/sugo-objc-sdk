//
//  MPUITextViewBinding.h
//  Sugo
//
//  Created by Zack on 24/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "MPEventBinding.h"

@interface MPUITextViewBinding : MPEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                      classAttr:(NSDictionary *)classAttr
                     attributes:(Attributes *)attributes;

@end
