//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPCGColorRefToNSStringValueTransformer

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
        if (value && CFGetTypeID((__bridge CFTypeRef)value) == CGColorGetTypeID()) {
            NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
            return [transformer transformedValue:[[UIColor alloc] initWithCGColor:(__bridge CGColorRef)value]];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value
{
    @try {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
        UIColor *uiColor =  [transformer reverseTransformedValue:value];
        return CFBridgingRelease(CGColorCreateCopy([uiColor CGColor]));
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
