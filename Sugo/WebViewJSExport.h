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

@interface WebViewJSExport : NSObject <JSExport>

+ (void)eventWithId:(NSString *)eventId Name:(NSString *)eventName Properties:(NSString *)properties;
+ (void)infoWithPath:(NSString *)path Nodes:(NSString *)nodes Width:(NSString *)width Height:(NSString *)height;

@end
