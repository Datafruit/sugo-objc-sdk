//
//  BindingUtils.h
//  Sugo
//
//  Created by 陈宇艺 on 2019/1/14.
//  Copyright © 2019 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface BindingUtils : NSObject
+(NSMutableDictionary *)requireExtraAttrWithValue:(NSDictionary *)classAttr p:(NSMutableDictionary *)p view:(UIView *)view;
@end

NS_ASSUME_NONNULL_END
