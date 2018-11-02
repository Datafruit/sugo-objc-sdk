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
@property NSString *viewportContent;
@property NSString *nodes;
@property NSString *distance;//Calculate the absolute value of moving the h5 element downward

@property NSMutableDictionary *wkWebViewDict;
@property NSMutableDictionary *isHashloadFinish;
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
    _viewportContent = @"";
    _nodes = @"";
    _distance=@"";
    _wkWebViewDict = [[NSMutableDictionary alloc]init];
    _isHashloadFinish = [[NSMutableDictionary alloc]init];
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

-(void)setupWebViewLoadStatus:(NSInteger)status hash:(NSInteger)hash{
    [_isHashloadFinish setObject:[NSString stringWithFormat:@"%ld",(long)status] forKey:[NSString stringWithFormat:@"hash"]];
}

-(NSInteger)requireWebViewLoadStatus:(NSInteger)hash{
    return [_isHashloadFinish[[NSString stringWithFormat:@"hash"]] integerValue];
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
                 @"viewportContent": _viewportContent,
                 @"nodes": _nodes,
                 @"distance":_distance
                 };
    }
}

-(NSDictionary *)getHTMLInfoWithHash:(NSInteger) hash{
    @synchronized(self) {
        if (_newFrame) {
            _newFrame = false;
        }
        return _wkWebViewDict[[NSString stringWithFormat:@"%ld",(long)hash]];
    }
}

- (void)setHTMLInfoWithTitle:(NSString *)title path:(NSString *)path width:(NSString *)width height:(NSString *)height viewportContent:(NSString *)viewportContent nodes:(NSString *)nodes
{
     @synchronized(self) {
         _title = title;
         _path = path;
         _width = width;
         _height = height;
         _viewportContent = viewportContent;
         _nodes = nodes;
         _newFrame = true;
     }
}

- (void)setHTMLInfoWithTitle:(NSString *)title path:(NSString *)path width:(NSString *)width height:(NSString *)height viewportContent:(NSString *)viewportContent nodes:(NSString *)nodes hash:(NSString *)hash
{
    @synchronized(self) {
        
        [_wkWebViewDict setObject: @{
                                     @"title": title,
                                     @"url": path,
                                     @"clientWidth": width,
                                     @"clientHeight": height,
                                     @"viewportContent": viewportContent,
                                     @"nodes": nodes
                                     } forKey:hash];
        _newFrame = true;
    }
}

- (void)setHTMLInfoWithTitle:(NSString *)title path:(NSString *)path width:(NSString *)width height:(NSString *)height viewportContent:(NSString *)viewportContent nodes:(NSString *)nodes distance:(NSString *)distance
{
    @synchronized(self) {
        _title = title;
        _path = path;
        _width = width;
        _height = height;
        _viewportContent = viewportContent;
        _nodes = nodes;
        _newFrame = true;
        _distance=distance;
    }
}

@end
