//
//  WebViewBindings+UIWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+UIWebView.h"
#import "WebViewBindings+WebView.h"
#import "SugoPageInfos.h"
#import "MPSwizzler.h"
#import "SugoPrivate.h"
#import "MPLogger.h"


@implementation WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView *)webView
{
    void (^uiWebViewDidStartLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        if (self.uiWebViewJavaScriptInjected) {
            self.uiWebViewJavaScriptInjected = NO;
            MPLogDebug(@"UIWebView Uninjected");
        }
    };
    
    void (^uiWebViewDidFinishLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        UIWebView *uiWebView = (UIWebView *)webView;
        if (uiWebView.request.URL.absoluteString.length <= 0
            || uiWebView.isLoading) {
            return;
        }
        if (!self.uiWebViewJavaScriptInjected) {
            [uiWebView stringByEvaluatingJavaScriptFromString:[self jsUIWebView]];
            self.uiWebViewJavaScriptInjected = YES;
        }
    };
    
    UIWebView *uiWebView = (UIWebView *)webView;
    if (!self.uiWebViewSwizzleRunning) {
        if (uiWebView.delegate) {
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                onClass:[uiWebView.delegate class]
                              withBlock:uiWebViewDidStartLoadBlock
                                  named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                onClass:[uiWebView.delegate class]
                              withBlock:uiWebViewDidFinishLoadBlock
                                  named:self.uiWebViewDidFinishLoadBlockName];
            self.uiWebViewSwizzleRunning = YES;
        }
    }
}

- (void)stopUIWebViewBindings
{
    if (self.uiWebViewSwizzleRunning) {
        if (self.uiWebViewDelegate) {
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                  onClass:[self.uiWebViewDelegate class]
                                    named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                  onClass:[self.uiWebViewDelegate class]
                                    named:self.uiWebViewDidFinishLoadBlockName];
        }
        self.uiWebViewJavaScriptInjected = NO;
        self.uiWebViewSwizzleRunning = NO;
        self.uiWebView = nil;
    }
}

- (void)updateUIWebViewBindings:(UIWebView *)webView
{
   if (self.uiWebViewSwizzleRunning) {
   }
}

- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName properties:(nullable NSString *)properties {
    
    NSData *pData = [properties dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *pJSON = [NSJSONSerialization JSONObjectWithData:pData
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
    if (pJSON != nil) {
        NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
        NSString *keyEventType = keys[@"EventType"];
        NSString *valueEventType = values[pJSON[keyEventType]];
        [pJSON setValue:valueEventType forKey:keyEventType];
        [[Sugo sharedInstance] trackEventID:eventID
                                  eventName:eventName
                                 properties:pJSON];
    } else {
        [[Sugo sharedInstance] trackEventID:eventID
                                  eventName:eventName];
    }
}

- (void)trackStayEventOfWebView:(UIWebView *)webView {
    NSString *eventString = [webView stringByEvaluatingJavaScriptFromString:@"sugo.trackStayEvent();"];
    NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *event = [NSJSONSerialization JSONObjectWithData:eventData
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    if (event[@"eventID"] && event[@"eventName"] && event[@"properties"]) {
        storage.eventID = (NSString *)event[@"eventID"];
        storage.eventName = (NSString *)event[@"eventName"];
        storage.properties = (NSString *)event[@"properties"];
        [self trackEventID:storage.eventID
                 eventName:storage.eventName
                properties:storage.properties];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldStartLoad = YES;
    NSURL *url = request.URL;
    MPLogDebug(@"%@: request = %@", NSStringFromSelector(_cmd), url.absoluteString);
    if ([url.scheme isEqualToString:@"sugo.npi"]) {
        NSString *npi = url.host;
        NSString *uuid = [url.query componentsSeparatedByString:@"="].lastObject;
        NSString *eventString = [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"sugo.dataOf('%@');", uuid]];
        NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *event = [NSJSONSerialization JSONObjectWithData:eventData
                                                              options:NSJSONReadingMutableContainers
                                                                error:nil];
        WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
        if ([npi isEqualToString:@"track"]) {
            storage.eventID = (NSString *)event[@"eventID"];
            storage.eventName = (NSString *)event[@"eventName"];
            storage.properties = (NSString *)event[@"properties"];
            [self trackEventID:storage.eventID eventName:storage.eventName properties:storage.properties];
            MPLogDebug(@"HTML Event: id = %@, name = %@", storage.eventID, storage.eventName);
        } else if ([npi isEqualToString:@"time"]) {
            NSString *eventName = [[NSString alloc] initWithString:(NSString *)event[@"eventName"]];
            if (eventName) {
                [[Sugo sharedInstance] timeEvent:eventName];
            }
        }
        shouldStartLoad = NO;
    }
    if (shouldStartLoad && webView.window != nil) {
        [self trackStayEventOfWebView:webView];
    }
    return shouldStartLoad;
}

- (NSString *)jsUIWebView
{
    NSString *js = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                    [self jsUIWebViewUtils],
                    [self jsUIWebViewSugoBegin],
                    [self jsUIWebViewVariables],
                    [self jsUIWebViewAPI],
                    [self jsUIWebViewBindings],
                    [self jsUIWebViewReport],
                    [self jsUIHeatMap],
                    [self jsUIWebViewExcute],
                    [self jsUIWebViewSugoEnd]];
    MPLogDebug(@"UIWebView JavaScript:\n%@", js);
    return js;
}

- (NSString *)jsUIWebViewUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsUIWebViewSugoBegin
{
    return [self jsSourceOfFileName:@"SugoBegin"];
}

- (NSString *)jsUIWebViewVariables
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
            MPLogError(@"exception: %@, decoding resJSON data: %@ -> %@",
                       exception,
                       infosJSON,
                       infosString);
        }
    }
    NSString *vcPath = [NSString stringWithFormat:@"sugo.view_controller = '%@';\n", self.uiVcPath];
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

- (NSString *)jsUIWebViewAPI
{
    NSString *api = [self jsSourceOfFileName:@"WebViewAPI.UI"];
    
    return api;
}

- (NSString *)jsUIWebViewBindings
{
    return [self jsSourceOfFileName:@"WebViewBindings.UI"];
}

- (NSString *)jsUIWebViewReport
{
    return [self jsSourceOfFileName:@"WebViewReport.UI"];
}

- (NSString *)jsUIHeatMap
{
    return [self jsSourceOfFileName:@"WebViewHeatmap"];
}

- (NSString *)jsUIWebViewExcute
{
    return [self jsSourceOfFileName:@"WebViewExcute.Sugo.UI"];
}

- (NSString *)jsUIWebViewSugoEnd
{
    return [self jsSourceOfFileName:@"SugoEnd"];
}

@end










