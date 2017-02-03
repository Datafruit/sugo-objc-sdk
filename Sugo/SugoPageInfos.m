//
//  SugoPageInfos.m
//  Sugo
//
//  Created by Zack on 3/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SugoPageInfos.h"

@implementation SugoPageInfos

+ (instancetype)global
{
    static SugoPageInfos *singleton = nil;
    if (!singleton) {
        singleton = [[self alloc] initSingleton];
    }
    return singleton;
}

- (instancetype)initSingleton
{
    _infos = [[NSMutableArray alloc] init];
    self  = [super init];
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"WebViewBindings init exception"
                                   reason:@"this is a singleton, try [WebViewBindings globalBindings]"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc
{
    [_infos removeAllObjects];
}

@end
