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


@implementation WebViewBindings (WKWebView)

- (void)startWKWebViewBindings:(WKWebView **)webView
{
    if (!self.wkWebViewJavaScriptInjected) {
        self.wkWebViewCurrentJSSugo = [self wkJavaScriptSugo];
        self.wkWebViewCurrentJSTrack = [self wkJavaScriptTrack];
        self.wkWebViewCurrentJSBindingSource = [self wkJavaScriptBindingSource];
        self.wkWebViewCurrentJSBindingExcute = [self wkJavaScriptBindingExcute];
        self.wkWebViewCurrentJSUtils = [self wkJavaScriptUtils];
        self.wkWebViewCurrentJSReportSource = [self wkJavaScriptReportSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSSugo];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSTrack];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSBindingSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSUtils];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSReportSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSBindingExcute];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewBindingsTrack"];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewBindingsTime"];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewReporter"];
        self.wkWebViewJavaScriptInjected = YES;
        MPLogDebug(@"WKWebView Injected");
    }
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindingsTrack"];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindingsTime"];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewReporter"];
        self.wkWebViewJavaScriptInjected = NO;
        self.wkWebView = nil;
    }
}

- (void)updateWKWebViewBindings:(WKWebView **)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        NSMutableArray<WKUserScript *> *userScripts = [[NSMutableArray<WKUserScript *> alloc]
                                                       initWithArray:(*webView).configuration.userContentController.userScripts];
        if ([userScripts containsObject:self.wkWebViewCurrentJSBindingSource]) {
            [userScripts removeObject:self.wkWebViewCurrentJSBindingSource];
        }
        if ([userScripts containsObject:self.wkWebViewCurrentJSBindingExcute]) {
            [userScripts removeObject:self.wkWebViewCurrentJSBindingExcute];
        }
        [(*webView).configuration.userContentController removeAllUserScripts];
        for (WKUserScript *userScript in userScripts) {
            [(*webView).configuration.userContentController addUserScript:userScript];
        }
        self.wkWebViewCurrentJSBindingSource = [self wkJavaScriptBindingSource];
        self.wkWebViewCurrentJSBindingExcute = [self wkWebViewCurrentJSBindingExcute];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSBindingSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSBindingExcute];
        MPLogDebug(@"WKWebView Updated");
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    if ([message.body isKindOfClass:[NSDictionary class]]) {
        if ([message.name isEqualToString:@"WKWebViewBindingsTrack"]) {
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
                NSDictionary *value = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValue"]];
                NSDictionary *key = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKey"]];
                NSString *keyEventType = key[@"EventType"];
                NSString *valueEventType = value[pJSON[keyEventType]];
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
        } else if ([message.name isEqualToString:@"WKWebViewBindingsTime"]) {
            NSDictionary *body = [[NSDictionary alloc] initWithDictionary:(NSDictionary *)message.body];
            NSString *eventName = [[NSString alloc] initWithString:(NSString *)body[@"eventName"]];
            if (eventName) {
                [[Sugo sharedInstance] timeEvent:eventName];
            }
        } else if ([message.name  isEqual: @"WKWebViewReporter"]) {
            NSDictionary *body = (NSDictionary *)message.body;
            WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
            if (body[@"path"])
            {
                storage.path = (NSString *)body[@"path"];
            }
            if (body[@"clientWidth"])
            {
                storage.width = (NSString *)body[@"clientWidth"];
            }
            if (body[@"clientHeight"])
            {
                storage.height = (NSString *)body[@"clientHeight"];
            }
            if (body[@"nodes"])
            {
                storage.nodes = (NSString *)body[@"nodes"];
            }
        }
    } else {
        MPLogDebug(@"Wrong message body type: name = %@, body = %@", message.name, message.body);
    }
}

- (WKUserScript *)wkJavaScriptSugo
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewSugo
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptTrack
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewTrack
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptBindingSource
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsSource
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptBindingExcute
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsExcute
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptUtils
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewUtils
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptReportSource
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewReportSource
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (NSString *)jsWKWebViewSugo
{
    return [self jsSourceOfFileName:@"Sugo"];
}

- (NSString *)jsWKWebViewTrack
{
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.wkWebView.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacement = [Sugo loadConfigurationPropertyListWithName:@"SugoResourcesPathReplacement"];
    if (replacement) {
        for (NSString *key in replacement.allKeys) {
            relativePath = [NSMutableString stringWithFormat:@"%@.replace(/%@/g, %@)",
                            relativePath,
                            key.length>0?key:@" ",
                            ((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@"''"];
            
            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key.length>0?key:@""]
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
            nativePath = [NSMutableString
                          stringWithString:[re stringByReplacingMatchesInString:nativePath
                                                                        options:0
                                                                          range:NSMakeRange(0, nativePath.length)
                                                                   withTemplate:((NSString *)replacement[key]).length>0?((NSString *)replacement[key]):@""]];
            
        }
    }
    relativePath = [NSMutableString stringWithFormat:@"%@;", relativePath];
    
    NSMutableString *pn = [[NSMutableString alloc] init];
    NSMutableString *ic = [[NSMutableString alloc] init];
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:nativePath]) {
                pn = info[@"page"];
                ic = info[@"code"];
                break;
            }
        }
    }
    NSMutableString *pageName = [NSMutableString stringWithFormat:@"sugo.page_name = %@;", pn.length>0?pn:@"''"];
    NSMutableString *initCode = [NSMutableString stringWithFormat:@"sugo.init_code = %@;", ic.length>0?ic:@"''"];

    NSString *wk = [self jsSourceOfFileName:@"WebViewTrack.WK"];
    
    return [[[relativePath stringByAppendingString:pageName]
             stringByAppendingString:initCode]
            stringByAppendingString:wk];
}

- (NSString *)jsWKWebViewBindingsSource
{
    NSString *vcPath = [NSString stringWithFormat:@"sugo.current_page = '%@::' + window.location.pathname;\n", self.wkVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *wk = [self jsSourceOfFileName:@"WebViewBindings.WK"];
    
    return [[vcPath stringByAppendingString:bindings]
            stringByAppendingString:wk];
}

- (NSString *)jsWKWebViewBindingsExcute
{
    return [self jsSourceOfFileName:@"WebViewBindings.excute"];
}

- (NSString *)jsWKWebViewUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsWKWebViewReportSource
{
    return [self jsSourceOfFileName:@"WebViewReport.WK"];
}


@end









