//
//  WebViewBindings+WKWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+WKWebView.h"
#import "WebViewBindings+WebView.h"
#import "Sugo.h"
#import "MPSwizzler.h"
#import "SugoPrivate.h"
#import "MPLogger.h"
#import "projectMacro.h"


@implementation WebViewBindings (WKWebView)

- (void)startWKWebViewBindings:(WKWebView **)webView
{
    self.wkWebViewCurrentJS = [self wkJavaScript];
    [(*webView).configuration.userContentController addUserScript:[self wkWebViewCurrentJS]];
    [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewBindingsTrack"];
    [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewBindingsTime"];
    [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewReporter"];
    [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"registerPathName"];
    MPLogDebug(@"WKWebView Injected");
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewBindingsTrack"];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewBindingsTime"];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewReporter"];
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"registerPathName"];
    self.wkWebView = nil;
}

- (void)updateWKWebViewBindings:(WKWebView **)webView
{
    NSMutableArray<WKUserScript *> *userScripts = [[NSMutableArray<WKUserScript *> alloc]
                                                   initWithArray:(*webView).configuration.userContentController.userScripts];
    
    if ([userScripts containsObject:self.wkWebViewCurrentJS]) {
        [userScripts removeObject:self.wkWebViewCurrentJS];
    }
    [(*webView).configuration.userContentController removeAllUserScripts];
    for (WKUserScript *userScript in userScripts) {
        [(*webView).configuration.userContentController addUserScript:userScript];
    }
    self.wkWebViewCurrentJS = [self wkJavaScript];
    [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJS];
    MPLogDebug(@"WKWebView Updated");
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        if ([message.name isEqualToString:@"SugoWKWebViewBindingsTrack"]) {
            NSDictionary *body = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)message.body];
            WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
            storage.eventID = (NSString *)body[@"eventID"];
            storage.eventName = (NSString *)body[@"eventName"];
            storage.properties = (NSString *)body[@"properties"];
            NSData *pData = [storage.properties dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *pJSON = [NSJSONSerialization JSONObjectWithData:pData
                                                                  options:NSJSONReadingMutableContainers
                                                                    error:nil];
            if (pJSON != nil)
            {
                NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
                NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
                NSString *keyEventType = keys[@"EventType"];
                NSString *valueEventType = values[pJSON[keyEventType]];
                [pJSON setValue:valueEventType forKey:keyEventType];
                [[Sugo sharedInstance] trackEventID:storage.eventID
                                   eventName:storage.eventName
                                  properties:pJSON];
            }
            else
            {
                [[Sugo sharedInstance] trackEventID:storage.eventID
                                   eventName:storage.eventName];
            }
            MPLogDebug(@"HTML Event: id = %@, name = %@", storage.eventID, storage.eventName);
        } else if ([message.name isEqualToString:@"SugoWKWebViewBindingsTime"]) {
            NSDictionary *body = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)message.body];
            NSString *eventName = [[NSString alloc] initWithString:(NSString *)body[@"eventName"]];
            if (eventName) {
                [[Sugo sharedInstance] timeEvent:eventName];
            }
        } else if ([message.name  isEqual: @"SugoWKWebViewReporter"]) {
            NSDictionary *body = (NSDictionary *)message.body;
            WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
            
            if (body[@"title"] && body[@"path"] && body[@"clientWidth"] && body[@"clientHeight"] && body[@"viewportContent"] && body[@"nodes"]) {
                [storage setHTMLInfoWithTitle:(NSString *)body[@"title"]
                                         path:(NSString *)body[@"path"]
                                        width:(NSString *)body[@"clientWidth"]
                                       height:(NSString *)body[@"clientHeight"]
                              viewportContent:(NSString *)body[@"viewportContent"]
                                        nodes:(NSString *)body[@"nodes"]];
            }
        }else if([message.name isEqual:@"registerPathName"]){
            NSDictionary *body = (NSDictionary *)message.body;
            NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
            [user setObject:body[@"path_name"] forKey:CURRENTCONTROLLER];
        }
    } else {
        MPLogDebug(@"Wrong message body type: name = %@, body = %@", message.name, message.body);
    }
}

- (WKUserScript *)wkJavaScript
{
    NSString *js = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                    [self jsWKWebViewSugoioKit],
                    [self jsWKWebViewSugoBegin],
                    [self jsWKWebViewVariables],
                    [self jsWKWebViewAPI],
                    [self jsWKWebViewBindings],
                    [self jsWKWebViewReport],
                    [self jsWKHeatMap],
                    [self jsWKWebViewExecute],
                    [self jsWKWebViewSugoEnd]];
    MPLogDebug(@"WKWebView JavaScript:\n%@", js);
    return [[WKUserScript alloc] initWithSource:js
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (NSString *)jsWKWebViewSugoioKit
{
    return [self jsSourceOfFileName:@"SugoioKit"];
}

- (NSString *)jsWKWebViewSugoBegin
{
    return [self jsSourceOfFileName:@"SugoBegin"];
}

- (NSString *)jsWKWebViewVariables
{
    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *rpr = (NSDictionary *)[userDefaults objectForKey:@"HomePath"];
    NSString *homePathKey = [[NSString alloc] init];
    NSString *homePathValue = [[NSString alloc] init];
    if (rpr) {
        homePathKey = (NSString *)rpr.allKeys.firstObject;
        homePathValue = (NSString *)rpr[homePathKey];
    }
    NSMutableArray *res = [[NSMutableArray alloc] init];
    NSMutableString *resString = nil;
    if (replacements) {
        for (NSString *replacement in replacements) {
            NSDictionary *r = (NSDictionary *)replacements[replacement];
            NSString *key = (NSString *)r.allKeys.firstObject;
            NSString *value = (NSString *)r[key];
            [res addObject:@{key: value}];
        }
        NSError *error = nil;
        NSData *resJSON = nil;
        @try {
            resJSON = [NSJSONSerialization dataWithJSONObject:res
                                                      options:NSJSONWritingPrettyPrinted
                                                        error:&error];
            resString = [[NSMutableString alloc] initWithData:resJSON
                                                     encoding:NSUTF8StringEncoding];
        } @catch (NSException *exception) {
            [[Sugo sharedInstance]trackEvent:SDKEXCEPTION properties:[[Sugo sharedInstance]exceptionInfoWithException:exception]];
            MPLogError(@"exception: %@, decoding resJSON data: %@ -> %@",
                       exception,
                       resJSON,
                       resString);
        }
    }
    NSMutableString *infosString = nil;
    if ([SugoPageInfos global].infos.count > 0) {
        NSError *error = nil;
        NSData *infosJSON = nil;
        @try {
            infosJSON = [NSJSONSerialization dataWithJSONObject:[SugoPageInfos global].infos
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:&error];
            infosString = [[NSMutableString alloc] initWithData:infosJSON
                                                       encoding:NSUTF8StringEncoding];
        } @catch (NSException *exception) {
            [[Sugo sharedInstance]trackEvent:SDKEXCEPTION properties:[[Sugo sharedInstance]exceptionInfoWithException:exception]];
            MPLogError(@"exception: %@, decoding resJSON data: %@ -> %@",
                       exception,
                       infosJSON,
                       infosString);
        }
    }
    NSString *vcPath = [NSString stringWithFormat:@"sugo.view_controller = '%@';\n", self.wkVcPath];
    NSString *homePath = [NSString stringWithFormat:@"sugo.home_path = '%@';\n", homePathKey];
    NSString *homePathReplacement = [NSString stringWithFormat:@"sugo.home_path_replacement = '%@';\n", homePathValue];
    NSString *regularExpressions = [NSString stringWithFormat:@"sugo.regular_expressions = %@;\n", resString?resString:@"[]"];
    NSString *pageInfos = [NSString stringWithFormat:@"sugo.page_infos = %@;\n", infosString?infosString:@"[]"];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *canTrackWebPage = [NSString stringWithFormat:@"sugo.can_track_web_page = %@;\n", SugoCanTrackWebPage?@"true":@"false"];
    NSString *canShowHeatMap = [NSString stringWithFormat:@"sugo.can_show_heat_map = %@;\n", self.isHeatMapModeOn?@"true":@"false"];
    NSString *heats = [NSString stringWithFormat:@"sugo.h5_heats = %@;\n", self.stringHeats];
    NSString *vars = [self jsSourceOfFileName:@"WebViewVariables"];
    
    
    NSString *variables = [[NSString alloc] initWithFormat:@"%@%@%@%@%@%@%@%@%@%@",
                           vcPath,
                           homePath,
                           homePathReplacement,
                           regularExpressions,
                           pageInfos,
                           bindings,
                           canTrackWebPage,
                           canShowHeatMap,
                           heats,
                           vars];
    
    return variables;
}

- (NSString *)jsWKWebViewAPI
{
    NSString *api = [self jsSourceOfFileName:@"WebViewAPI.WK"];
    
    return api;
}

- (NSString *)jsWKWebViewBindings
{
    return [self jsSourceOfFileName:@"WebViewBindings.WK"];
}

- (NSString *)jsWKWebViewReport
{
    return [self jsSourceOfFileName:@"WebViewReport.WK"];
}

- (NSString *)jsWKHeatMap
{
    return [self jsSourceOfFileName:@"WebViewHeatmap"];
}

- (NSString *)jsWKWebViewExecute
{
    return [self jsSourceOfFileName:@"WebViewExecute.Sugo.WK"];
}

- (NSString *)jsWKWebViewSugoEnd
{
    return [self jsSourceOfFileName:@"SugoEnd"];
}

@end









