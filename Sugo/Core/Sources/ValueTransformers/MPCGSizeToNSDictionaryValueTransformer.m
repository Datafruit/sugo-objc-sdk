//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPCGSizeToNSDictionaryValueTransformer

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
        if ([value respondsToSelector:@selector(CGSizeValue)]) {
            CGSize size = [value CGSizeValue];
            size.width = isnormal(size.width) ? size.width : 0.0f;
            size.height = isnormal(size.height) ? size.height : 0.0f;
            return CFBridgingRelease(CGSizeCreateDictionaryRepresentation(size));
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    CGSize size = CGSizeZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGSizeMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &size)) {
        return [NSValue valueWithCGSize:size];
    }

    return [NSValue valueWithCGSize:CGSizeZero];
}

@end
