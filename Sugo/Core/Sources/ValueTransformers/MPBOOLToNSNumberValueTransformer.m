//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"

@implementation MPBOOLToNSNumberValueTransformer

+ (Class)transformedValueClass
{
    return [@YES class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if ([value respondsToSelector:@selector(boolValue)]) {
        return @([value boolValue]);
    }

    return nil;
}

@end
