//
//  HeatMap.m
//  Sugo
//
//  Created by Zack on 27/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "HeatMap.h"
#import "MPLogger.h"

@implementation HeatMap

- (instancetype)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _mode = false;
        _data = data;
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

// On mode
- (void)turnOn {
    [self render];
}

- (void)render {
    
}

- (NSDictionary *)parse {
    NSMutableDictionary *heats = [NSMutableDictionary dictionary];
    for (NSString *path in [self serialized].allKeys) {
        NSString *page = [self pageOfPath:path];
        NSNumber *rate = [self rateOfPath:path];
        [heats addEntriesFromDictionary:@{page: @{path: rate}}];
    }
    return heats;
}

- (NSNumber *)rateOfPath:(NSString *)path {
    NSNumber *rate = [NSNumber numberWithDouble:0.0];
    
    return rate;
}

- (NSString *)pageOfPath:(NSString *)path {
    NSString *page = @"";
    if ([[path componentsSeparatedByString:@"/"] count] > 2) {
        page = [path componentsSeparatedByString:@"/"][1];
    }
    return page;
}

- (NSDictionary *)serialized {
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

// Off mode
- (void)turnOff {
    [self wipe];
}

- (void)wipe {
    
}

@end
