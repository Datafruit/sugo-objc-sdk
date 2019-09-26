//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <ImageIO/ImageIO.h>
#import "MPValueTransformers.h"
#import "ExceptionUtils.h"
@implementation MPUIImageToNSDictionaryValueTransformer

static NSMutableDictionary *imageCache;

+ (void)load {
    imageCache = [NSMutableDictionary dictionary];
}

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
    @try {
        NSDictionary *transformedValue = nil;

        if ([value isKindOfClass:[UIImage class]]) {
            UIImage *image = value;

            NSValueTransformer *sizeTransformer = [NSValueTransformer valueTransformerForName:NSStringFromClass([MPCGSizeToNSDictionaryValueTransformer class])];
            NSValueTransformer *insetsTransformer = [NSValueTransformer valueTransformerForName:NSStringFromClass([MPUIEdgeInsetsToNSDictionaryValueTransformer class])];

            NSValue *sizeValue = [NSValue valueWithCGSize:image.size];
            NSValue *capInsetsValue = [NSValue valueWithUIEdgeInsets:image.capInsets];
            NSValue *alignmentRectInsetsValue = [NSValue valueWithUIEdgeInsets:image.alignmentRectInsets];

            NSArray *images = image.images ?: @[ image ];

            NSMutableArray *imageDictionaries = [NSMutableArray array];
            for (UIImage *image in images) {
                NSDictionary *imageDictionary = @{ @"scale": @(image.scale),
                                                   @"mime_type": @"image/png" };

                [imageDictionaries addObject:imageDictionary];
            }

            transformedValue = @{
               @"imageOrientation": @(image.imageOrientation),
               @"size": [sizeTransformer transformedValue:sizeValue],
               @"renderingMode": @(image.renderingMode),
               @"resizingMode": @(image.resizingMode),
               @"duration": @(image.duration),
               @"capInsets": [insetsTransformer transformedValue:capInsetsValue],
               @"alignmentRectInsets": [insetsTransformer transformedValue:alignmentRectInsetsValue],
               @"images": [imageDictionaries copy],
            };
        }

        return transformedValue;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
