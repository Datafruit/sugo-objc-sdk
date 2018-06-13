//
//  MPUITableViewBinding.h
//  Sugo
//
//  Created by Amanda Canyon on 8/5/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPEventBinding.h"

@interface MPUITableViewBinding : MPEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                     attributes:(Attributes *)attributes;


@end
