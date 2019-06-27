//
//  MPUICollectionViewCellBinding.h
//  Sugo
//
//  Created by 陈宇艺 on 2019/6/12.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "MPEventBinding.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPUICollectionViewCellBinding : MPEventBinding

- (instancetype)init __unavailable;
- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                      classAttr:(NSDictionary *)classAttr
                     attributes:(Attributes *)attributes;

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                      classAttr:(NSDictionary *)classAttr
                     attributes:(Attributes *)attributes;

@end

NS_ASSUME_NONNULL_END
