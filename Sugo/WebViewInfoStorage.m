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

@property BOOL newFrame;
@property NSString *title;
@property NSString *path;
@property NSString *width;
@property NSString *height;
@property NSString *nodes;
    
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
    _newFrame = false;
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

- (BOOL)hasNewFrame {
    
    @synchronized(self) {
        return _newFrame;
    }
}
    
- (void)setHasNewFrame:(BOOL)hasNewFrame {
    
    @synchronized(self) {
        _newFrame = hasNewFrame;
    }
}

- (NSDictionary *)getHTMLInfo
{
    @synchronized(self) {
        if (_newFrame) {
            _newFrame = false;
        }
        return @{
                 @"title": _title,
                 @"url": _path,
                 @"clientWidth": _width,
                 @"clientHeight": _height,
                 @"nodes": _nodes
                 };
    }
}

- (void)setHTMLInfoWithTitle:(NSString *)title path:(NSString *)path width:(NSString *)width height:(NSString *)height nodes:(NSString *)nodes
{
     @synchronized(self) {
         _title = title;
         _path = path;
         _width = width;
         _height = height;
         _nodes = nodes;
         _newFrame = true;
     }
}

@end
