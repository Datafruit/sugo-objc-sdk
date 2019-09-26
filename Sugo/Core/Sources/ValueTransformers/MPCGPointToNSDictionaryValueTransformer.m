//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPCGPointToNSDictionaryValueTransformer

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
        if ([value respondsToSelector:@selector(CGPointValue)]) {
            CGPoint point = [value CGPointValue];
            point.x = isnormal(point.x) ? point.x : 0.0f;
            point.y = isnormal(point.y) ? point.y : 0.0f;
            return CFBridgingRelease(CGPointCreateDictionaryRepresentation(point));
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    @try {
        CGPoint point = CGPointZero;
        if ([value isKindOfClass:[NSDictionary class]] && CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &point)) {
            return [NSValue valueWithCGPoint:point];
        }

        return [NSValue valueWithCGPoint:CGPointZero];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
