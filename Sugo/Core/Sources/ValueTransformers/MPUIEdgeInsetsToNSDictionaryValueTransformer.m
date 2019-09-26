//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPUIEdgeInsetsToNSDictionaryValueTransformer

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    @try {
        if ([value respondsToSelector:@selector(UIEdgeInsetsValue)]) {
            UIEdgeInsets edgeInsetsValue = [value UIEdgeInsetsValue];

            return @{
                @"top"    : @(edgeInsetsValue.top),
                @"bottom" : @(edgeInsetsValue.bottom),
                @"left"   : @(edgeInsetsValue.left),
                @"right"  : @(edgeInsetsValue.right)
            };
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    @try {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dictionaryValue = value;

            id top = dictionaryValue[@"top"];
            id bottom = dictionaryValue[@"bottom"];
            id left = dictionaryValue[@"left"];
            id right = dictionaryValue[@"right"];

            if (top && bottom && left && right) {
                UIEdgeInsets edgeInsets = UIEdgeInsetsMake([top floatValue], [left floatValue], [bottom floatValue], [right floatValue]);
                return [NSValue valueWithUIEdgeInsets:edgeInsets];
            }
        }

        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}


@end
