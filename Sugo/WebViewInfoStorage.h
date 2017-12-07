//
//  WebViewInfoStorage.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewInfoStorage : NSObject

@property NSString *eventID;
@property NSString *eventName;
@property NSString *properties;

+ (instancetype)globalStorage;

- (BOOL)hasNewFrame;
- (void)setHasNewFrame:(BOOL)hasNewFrame;
- (NSDictionary *)getHTMLInfo;
- (void)setHTMLInfoWithTitle:(NSString *)title path:(NSString *)path width:(NSString *)width height:(NSString *)height nodes:(NSString *)nodes;

@end
