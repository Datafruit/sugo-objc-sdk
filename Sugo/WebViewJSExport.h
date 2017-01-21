//
//  WebViewJSExport.h
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "WebViewInfoStorage.h"

@protocol WebViewJSExportProtocol <NSObject, JSExport>

+ (void)trackOfId:(NSString *)eventId
             name:(NSString *)eventName
       properties:(NSString *)properties;

+ (void)timeOfEvent:(NSString *)event;

+ (void)infoOfPath:(NSString *)path
             nodes:(NSString *)nodes
             width:(NSString *)width
            height:(NSString *)height;

@end

@interface WebViewJSExport : NSObject <WebViewJSExportProtocol>

+ (void)trackOfId:(NSString *)eventId
             name:(NSString *)eventName
       properties:(NSString *)properties;

+ (void)timeOfEvent:(NSString *)event;

+ (void)infoOfPath:(NSString *)path
             nodes:(NSString *)nodes
             width:(NSString *)width
            height:(NSString *)height;

@end