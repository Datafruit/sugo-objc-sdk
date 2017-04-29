//
//  HeatMap.m
//  Sugo
//
//  Created by Zack on 27/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "HeatMap.h"
#import "HeatMapLayer.h"
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
        _hmPaths = [NSMutableArray array];
    }
    return self;
}

- (void)switchMode:(BOOL)mode {
    if (self.mode == mode) {
        return;
    }
    if (mode == true) {
        self.mode = true;
    } else if (mode == false) {
        self.mode = false;
    }
}

- (void)renderObjectOfPath:(NSString *)path {
    
    NSDictionary *heats = [self parse];
    
    if (!heats[path] || [self.hmPaths containsObject:path]) {
        return;
    }
    
    NSObject *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    MPObjectSelector *selector = [[MPObjectSelector alloc] initWithString:path];
    NSArray *objects = [selector selectFromRoot:root];
    for (UIControl *control in objects) {
        HeatMapLayer *hmLayer = [[HeatMapLayer alloc] initWithFrame:control.layer.bounds
                                                               heat:[self colorOfRate:[heats[path] doubleValue]]];
        [hmLayer setNeedsDisplay];
        [control.layer addSublayer:hmLayer];
        [self.hmPaths addObject:path];
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

@end











