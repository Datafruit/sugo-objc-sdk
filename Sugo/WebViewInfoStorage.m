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

+ (instancetype)globalStorage
{
    static WebViewInfoStorage *singleton = nil;
    if (!singleton) {
        singleton = [[self alloc] initSingleton];
    }
    return singleton;
}

- (instancetype)initSingleton
{
    self  = [super init];
    _eventID = @"";
    _eventName = @"";
    _properties = @"";
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
