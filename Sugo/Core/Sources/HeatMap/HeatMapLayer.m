//
//  HeatMapLayer.m
//  Sugo
//
//  Created by Zack on 29/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "HeatMapLayer.h"
#import <UIKit/UIKit.h>
#import "ExceptionUtils.h"
@implementation HeatMapLayer

- (instancetype)initWithFrame:(CGRect)frame heat:(NSDictionary *)heat
{
    self = [super init];
    if (self) {
        self.frame = frame;
        _heat = heat;
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    @try {
        UIGraphicsPushContext(ctx);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGFloat red = [self.heat[@"red"] doubleValue] / 255;
        CGFloat green = [self.heat[@"green"] doubleValue] / 255;
        CGFloat blue = [self.heat[@"blue"] doubleValue] / 255;
        CGFloat alpha = 0.8;
        CGFloat colors[] = {red, green, blue, alpha,
                            1, 1, 1, alpha};
        CGFloat locations[]={0,1};
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace,
                                                                     colors,
                                                                     locations,
                                                                     2);
        CGFloat radius = MAX(self.bounds.size.width / 2,
                             self.bounds.size.height / 2);
        CGContextDrawRadialGradient (context,
                                     gradient,
                                     self.position,
                                     0,
                                     self.position,
                                     radius,
                                     kCGGradientDrawsAfterEndLocation);
        CGColorSpaceRelease(colorSpace);
        CGGradientRelease(gradient);
        
        CGContextSaveGState(context);
        CGContextRestoreGState(context);
        UIGraphicsPopContext();
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

@end
