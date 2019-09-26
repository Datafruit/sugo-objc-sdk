//
//  MPUILayoutSupportToNSStringValueTransformer.m
//  Sugo
//
//  Created by Zack on 2/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPUILayoutSupportToNSStringValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    @try {
        if ([value conformsToProtocol:@protocol(UILayoutSupport)]) {
            id<UILayoutSupport> v = value;
            NSString *length = [NSString stringWithFormat:@"%f", v.length];
            return length;
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

@end
