//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPCGRectToNSDictionaryValueTransformer

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
        if ([value respondsToSelector:@selector(CGRectValue)]) {
            CGRect rect = [value CGRectValue];
            rect.origin.x = isnormal(rect.origin.x) ? rect.origin.x : 0.0f;
            rect.origin.y = isnormal(rect.origin.y) ? rect.origin.y : 0.0f;
            rect.size.width = isnormal(rect.size.width) ? rect.size.width : 0.0f;
            rect.size.height = isnormal(rect.size.height) ? rect.size.height : 0.0f;
            return CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect));
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    @try {
        CGRect rect = CGRectZero;
        if ([value isKindOfClass:[NSDictionary class]] && CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &rect)) {
            return [NSValue valueWithCGRect:rect];
        }

        return [NSValue valueWithCGRect:CGRectZero];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
