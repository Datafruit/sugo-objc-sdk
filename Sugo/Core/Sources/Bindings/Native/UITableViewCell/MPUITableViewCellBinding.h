//
//  MPUITableViewCellBinding.h
//  Sugo
//
//  Created by 陈宇艺 on 2018/10/21.
//  Copyright © 2018年 sugo. All rights reserved.
//

#import "MPEventBinding.h"

@interface MPUITableViewCellBinding : MPEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                     attributes:(Attributes *)attributes;

@end
