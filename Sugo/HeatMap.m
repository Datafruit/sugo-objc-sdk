//
//  HeatMap.m
//  Sugo
//
//  Created by Zack on 27/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "HeatMap.h"
#import <UIKit/UIKit.h>
#import "MPLogger.h"
#import "MPObjectSelector.h"

@implementation HeatMap

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _mode = false;
        _data = data;
        _coldColor = @{@"red": @211, @"green": @177, @"blue": @125};
        _hotColor = @{@"red": @255, @"green": @45, @"blue": @81};
    }
    return self;
}

- (void)switchMode:(BOOL)mode {
    if (self.mode == mode) {
        return;
    }
    if (mode == true) {
        [self turnOn];
    } else if (mode == false) {
        [self turnOff];
    }
}

// Color
- (NSDictionary *)colorOfRate:(double)rate {
    NSMutableDictionary *color = [[NSMutableDictionary alloc] initWithDictionary:self.coldColor];
    
    double red = ([self.hotColor[@"red"] doubleValue] - [self.coldColor[@"red"] doubleValue]) * rate;
    double green = ([self.hotColor[@"green"] doubleValue] - [self.coldColor[@"green"] doubleValue]) * rate;
    double blue = ([self.hotColor[@"blue"] doubleValue] - [self.coldColor[@"blue"] doubleValue]) * rate;
    
    color[@"red"] = @([color[@"red"] doubleValue] + red);
    color[@"green"] = @([color[@"green"] doubleValue] + green);
    color[@"blue"] = @([color[@"blue"] doubleValue] + blue);
    
    return color;
}

- (UIView *)heatViewWithBounds:(CGRect)bounds {
    UIView *heatView = [[UIView alloc] initWithFrame:bounds];
    return heatView;
}

// On mode
- (void)turnOn {
    [self renderNative];
}

- (void)renderNative {
    
    NSDictionary *heats = [self parse];
    
    NSObject *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    for (NSString *path in heats.allKeys) {
        MPObjectSelector *selector = [[MPObjectSelector alloc] initWithString:path];
        NSArray *objects = [selector selectFromRoot:root];
        for (UIControl *control in objects) {
            // TODO: render control
            CALayer *heatLayer = [self heatLayerWithFrame:control.layer.bounds rate:[heats[path] doubleValue]];
            [control.layer addSublayer:heatLayer];
        }
    }
}

- (CALayer *)heatLayerWithFrame:(CGRect)frame rate:(double)rate {
    
    CALayer *heatLayer = [CALayer layer];
    heatLayer.frame = frame;
    heatLayer.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0].CGColor;
    
    NSDictionary *color = [self colorOfRate:rate];
    UIColor *heatColor = [UIColor colorWithRed:[color[@"red"] doubleValue] / 255
                                         green:[color[@"green"] doubleValue] / 255
                                          blue:[color[@"blue"] doubleValue] / 255
                                         alpha:1];
    UIColor *centerColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0];
    
    
    CAGradientLayer *gradientLayer1 = [CAGradientLayer layer];
    gradientLayer1.frame = CGRectMake(0, 0, frame.size.width / 2, frame.size.width / 2);
    gradientLayer1.colors = @[(id)heatColor.CGColor, (id)centerColor.CGColor];
    gradientLayer1.locations = @[@0.0f, @1.0f];
    gradientLayer1.startPoint = CGPointMake(0, 0);
    gradientLayer1.endPoint = CGPointMake(1, 1);
    
    CAGradientLayer *gradientLayer2 = [CAGradientLayer layer];
    gradientLayer2.frame = CGRectMake(frame.size.width / 2, 0, frame.size.width / 2, frame.size.width / 2);
    gradientLayer2.colors = @[(id)heatColor.CGColor, (id)centerColor.CGColor];
    gradientLayer2.locations = @[@0.0f, @1.0f];
    gradientLayer2.startPoint = CGPointMake(1, 0);
    gradientLayer2.endPoint = CGPointMake(0, 1);
    
    CAGradientLayer *gradientLayer3 = [CAGradientLayer layer];
    gradientLayer3.frame = CGRectMake(0, frame.size.height / 2, frame.size.width / 2, frame.size.width / 2);
    gradientLayer3.colors = @[(id)heatColor.CGColor, (id)centerColor.CGColor];
    gradientLayer3.locations = @[@0.0f, @1.0f];
    gradientLayer3.startPoint = CGPointMake(0, 1);
    gradientLayer3.endPoint = CGPointMake(1, 0);

    CAGradientLayer *gradientLayer4 = [CAGradientLayer layer];
    gradientLayer4.frame = CGRectMake(frame.size.width / 2, frame.size.height / 2, frame.size.width / 2, frame.size.width / 2);
    gradientLayer4.colors = @[(id)heatColor.CGColor, (id)centerColor.CGColor];
    gradientLayer4.locations = @[@0.0f, @1.0f];
    gradientLayer4.startPoint = CGPointMake(1, 1);
    gradientLayer4.endPoint = CGPointMake(0, 0);
    
    [heatLayer addSublayer:gradientLayer1];
    [heatLayer addSublayer:gradientLayer2];
    [heatLayer addSublayer:gradientLayer3];
    [heatLayer addSublayer:gradientLayer4];
    
    return heatLayer;
}

- (NSDictionary *)parse {
    
    NSMutableDictionary *heats = [NSMutableDictionary dictionary];
    
    NSDictionary *nativeEventBindings = [self serializedNativeEventBindings];
    if (nativeEventBindings) {
        NSDictionary *heatMap = [self serializedHeatMap];
        
        NSMutableDictionary *hs = [NSMutableDictionary dictionary];
        NSMutableDictionary *locations = [NSMutableDictionary dictionary];
        for (NSString *eventId in heatMap.allKeys) {
            NSString *path = nativeEventBindings[eventId][@"path"];
            NSString *page = [self pageOfPath:path];
            if (path && page) {
                [locations addEntriesFromDictionary:@{path: page}];
                [hs addEntriesFromDictionary:@{path: heatMap[eventId]}];
            }
        }
        
        NSMutableDictionary *pages = [NSMutableDictionary dictionary];
        for (NSString *path in locations.allKeys) {
            NSString *page = locations[path];
            NSMutableArray *paths = [NSMutableArray array];
            if (pages[page]) {
                paths = pages[page];
            }
            [paths addObject:path];
            [pages addEntriesFromDictionary:@{page: paths}];
        }
        
        for (NSString *page in pages.allKeys) {
            double events = 0.0;
            for (NSString *path in pages[page]) {
                events = events + [hs[path] doubleValue];
            }
            for (NSString *path in pages[page]) {
                if (hs[path]) {
                    NSNumber *rate = @([hs[path] doubleValue] / events);
                    [heats addEntriesFromDictionary:@{path: rate}];
                }
            }
        }
    }
    return heats;
}

- (NSString *)pageOfPath:(NSString *)path {
    NSString *page = @"";
    if ([[path componentsSeparatedByString:@"/"] count] > 2) {
        page = [path componentsSeparatedByString:@"/"][1];
    }
    return page;
}

- (NSDictionary *)serializedHeatMap {
    NSMutableDictionary *heats = [NSMutableDictionary dictionary];
    @try {
        NSDictionary *object = [NSJSONSerialization JSONObjectWithData:self.data
                                                               options:(NSJSONReadingOptions)0
                                                                 error:nil];
        heats = object[@"heat_map"];
    } @catch (NSException *exception) {
        MPLogError(@"exception: %@, data: %@, heats: %@", exception, self.data, heats);
    }
    return heats;
}

- (NSDictionary *)serializedNativeEventBindings {
    NSMutableDictionary *nativeEventBindings = [NSMutableDictionary dictionary];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *cacheData = [userDefaults dataForKey:@"SugoEventBindings"];
    if (cacheData) {
        @try {
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:cacheData
                                                                   options:(NSJSONReadingOptions)0
                                                                     error:nil];
            NSDictionary *eventBindings = object[@"event_bindings"];
            for (NSDictionary *binding in eventBindings) {
                if ([(NSString *)binding[@"event_type"] isEqualToString:@"ui_control"]) {
                    [nativeEventBindings addEntriesFromDictionary:@{binding[@"event_id"]: binding}];
                }
            }
        } @catch (NSException *exception) {
            MPLogError(@"exception: %@, data: %@, heats: %@", exception, self.data);
        }
    }
    
    return nativeEventBindings;
}

// Off mode
- (void)turnOff {
    [self wipe];
}

- (void)wipe {
    
}

@end











