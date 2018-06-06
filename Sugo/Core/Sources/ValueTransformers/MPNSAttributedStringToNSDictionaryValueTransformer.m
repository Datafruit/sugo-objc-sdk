//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPLogger.h"
#import "MPValueTransformers.h"

@implementation MPNSAttributedStringToNSDictionaryValueTransformer

+ (Class)transformedValueClass
{
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;  // Origin is YES
}

- (id)transformedValue:(id)value
{
    if ([value isKindOfClass:[NSAttributedString class]]) {
        NSMutableAttributedString *attributedString = [value mutableCopy];
        [attributedString beginEditing];
        __block BOOL safe = NO;
        [attributedString enumerateAttribute:NSParagraphStyleAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value) {
                NSParagraphStyle *paragraphStyle = value;
                if([paragraphStyle respondsToSelector:@selector(headIndent)]) {
                    safe = YES;
                }
            }
        }];
        if (!safe) {
            [attributedString removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, attributedString.length)];
        }
        [attributedString endEditing];
        
        return @{
                 @"mime_type": @"text/html"
                 };
    }

    return nil;
}

@end
