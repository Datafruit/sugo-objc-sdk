//
//  MPUICollectionViewBinding.h
//  Sugo
//
//  Created by lzackx on 2017/12/11.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "MPEventBinding.h"

@interface MPUICollectionViewBinding : MPEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                      classAttr:(NSDictionary *)classAttr
                     attributes:(Attributes *)attributes;


@end
