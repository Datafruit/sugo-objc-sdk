//
//  WebViewJSExport.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewJSExport.h"
#import "Sugo.h"
#import "SugoPrivate.h"

@implementation WebViewJSExport

+ (void)trackOfId:(NSString *)eventId
             name:(NSString *)eventName
       properties:(NSString *)properties
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
        NSDictionary *value = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValue"]];
        NSDictionary *key = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKey"]];
        NSString *keyEventType = key[@"EventType"];
        NSString *valueEventType = value[pJSON[keyEventType]];
        [pJSON setValue:valueEventType forKey:keyEventType];
        [[Sugo sharedInstance] trackEventID:storage.eventID
                           eventName:storage.eventName
                          properties:pJSON];
    }
    else {
        [[Sugo sharedInstance] trackEventID:storage.eventID
                           eventName:storage.eventName];
    }
    NSLog(@"HTML Event: id = %@, name = %@", storage.eventID, storage.eventName);
}

+ (void)timeOfEvent:(NSString *)event
{
    [[Sugo sharedInstance] timeEvent:event];
}

+ (void)infoOfPath:(NSString *)path
             nodes:(NSString *)nodes
             width:(NSString *)width
            height:(NSString *)height
{
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    storage.path = path;
    storage.nodes = nodes;
    storage.width = width;
    storage.height = height;
}

@end
