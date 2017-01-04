//
//  WebViewJSExport.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewJSExport.h"
#import "Sugo.h"

@implementation WebViewJSExport

+ (void)eventWithId:(NSString *)eventId Name:(NSString *)eventName Properties:(NSString *)properties
{
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    storage.eventID = eventId;
    storage.eventName = eventName;
    storage.properties = properties;
    NSData *pData = [properties dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *pJSON = [NSJSONSerialization JSONObjectWithData:pData
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
    if (pJSON != nil)
    {
        [[Sugo sharedInstance] track:storage.eventID
                               eventName:storage.eventName
                              properties:pJSON];
    }
    else {
        [[Sugo sharedInstance] track:storage.eventID
                               eventName:storage.eventName];
    }
}

+ (void)infoWithPath:(NSString *)path Nodes:(NSString *)nodes Width:(NSString *)width Height:(NSString *)height
{
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    storage.path = path;
    storage.nodes = nodes;
    storage.width = width;
    storage.height = height;
}

@end
