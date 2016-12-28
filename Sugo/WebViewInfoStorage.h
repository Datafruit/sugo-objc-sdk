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
@property NSString *path;
@property NSString *width;
@property NSString *height;
@property NSString *nodes;

+ (instancetype)globalStorage;

@end
