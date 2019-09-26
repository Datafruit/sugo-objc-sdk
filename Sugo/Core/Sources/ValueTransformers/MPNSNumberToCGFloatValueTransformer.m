//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPNSNumberToCGFloatValueTransformer

+ (Class)transformedValueClass
{
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    @try {
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber *) value;

            // if the number is not a cgfloat, cast it to a cgfloat
            if (strcmp(number.objCType, @encode(CGFloat)) != 0) {
                if (strcmp(@encode(CGFloat), @encode(double)) == 0) {
                    value = @(number.doubleValue);
                } else {
                    value = @(number.floatValue);
                }
            }

            return value;
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

@end
