//
//  WebViewInfoStorage.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebViewInfoStorage.h"

@interface WebViewInfoStorage ()

@end

@implementation WebViewInfoStorage

static WebViewInfoStorage *singleton = nil;

+ (instancetype)globalStorage
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
    self  = [super init];
    _eventID = @"";
    _eventName = @"";
    _properties = @"";
    _title = @"";
    _path = @"";
    _width = @"";
    _height = @"";
    _nodes = @"";
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"WebViewInfoStorage init exception"
                                   reason:@"this is a singleton, try [WebViewInfoStorage globalStorage]"
                                 userInfo:nil];
    return nil;
}

@end
