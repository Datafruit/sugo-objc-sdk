//
//  BindingUtils.m
//  Sugo
//
//  Created by 陈宇艺 on 2019/1/14.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "BindingUtils.h"
#import "Sugo.h"
@implementation BindingUtils

+(NSMutableDictionary *)requireExtraAttrWithValue:(NSDictionary *)classAttr p:(NSMutableDictionary *)p view:(UIView *)view{
    BOOL isTrue =  [[Sugo sharedInstance] getStartExtraAttrFuncion];
    if (!isTrue) {
        return p;
    }
    
    for (NSString *key in classAttr){
        NSString *value = classAttr[key];
        NSArray *array = [value componentsSeparatedByString:@","];
        NSString *data = @"";
        for(int i=0;i<array.count;i++){
            id attr = [view valueForKey:array[i]];
            if (i>0) {
                data = [data stringByAppendingString:[NSString stringWithFormat:@";%@",attr]];
            }else{
                data = [data stringByAppendingString:[NSString stringWithFormat:@"%@",attr]];
            }
        }
        p[key] = data;
    }
    return p;
}

@end
