//
//  SugoPageInfos.m
//  Sugo
//
//  Created by Zack on 3/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SugoPageInfos.h"

@implementation SugoPageInfos

static SugoPageInfos *singleton = nil;

+ (instancetype)global
{
    @synchronized(self) {
        if (singleton == nil) {
            singleton = [[self alloc] initSingleton];
        }
    }
    return singleton;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    @synchronized(self) {
        if (singleton == nil) {
            singleton = [super allocWithZone:zone];
            return singleton;
        }
    }
    return nil;
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
                                   reason:@"this is a singleton, try [SugoPageInfos global]"
                                 userInfo:nil];
    return nil;
}

- (void)dealloc
{
    [_infos removeAllObjects];
}

@end
