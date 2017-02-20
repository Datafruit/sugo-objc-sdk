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
        self.wkWebViewCurrentJS = [self wkJavaScript];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJS];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewBindingsTrack"];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewBindingsTime"];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"SugoWKWebViewReporter"];
        self.wkWebViewJavaScriptInjected = YES;
        MPLogDebug(@"WKWebView Injected");
    }
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewBindingsTrack"];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewBindingsTime"];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"SugoWKWebViewReporter"];
        self.wkWebViewJavaScriptInjected = NO;
        self.wkWebView = nil;
    }
}

- (void)updateWKWebViewBindings:(WKWebView **)webView
{
    if (self.wkWebViewJavaScriptInjected) {
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

- (WKUserScript *)wkJavaScript
{
    NSString *js = [[NSString alloc] initWithFormat:@"%@\n%@\n%@\n%@\n%@\n%@\n%@\n%@\n",
                    [self jsWKWebViewUtils],
                    [self jsWKWebViewSugoBegin],
                    [self jsWKWebViewVariables],
                    [self jsWKWebViewAPI],
                    [self jsWKWebViewBindings],
                    [self jsWKWebViewReport],
                    [self jsWKWebViewExcute],
                    [self jsWKWebViewSugoEnd]];
    NSLog(@"WKWebView JavaScript:\n%@", js);
    
    return [[WKUserScript alloc] initWithSource:js
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (NSString *)jsWKWebViewUtils
{
    return [self jsSourceOfFileName:@"Utils"];
}

- (NSString *)jsWKWebViewSugoBegin
{
    return [self jsSourceOfFileName:@"SugoBegin"];
}

- (NSString *)jsWKWebViewVariables
{
    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.wkWebView.URL.path];
    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
    if (replacements) {
        for (NSString *replacement in replacements) {
            NSDictionary *r = (NSDictionary *)replacements[replacement];
            NSString *key = (NSString *)r.allKeys.firstObject;
            NSString *value = (NSString *)r[key];
            relativePath = [NSMutableString stringWithFormat:@"%@.replace('%@', %@)",
                            relativePath,
                            key,
                            value.length>0?value:@"''"];
        }
        if (replacements[@"HomePath"]) {
            NSString *key = (NSString *)((NSDictionary *)replacements[@"HomePath"]).allKeys.firstObject;
            NSString *value = (NSString *)((NSDictionary *)replacements[@"HomePath"])[key];
            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key]
                                                                           options:NSRegularExpressionAnchorsMatchLines
                                                                             error:nil];
            nativePath = [NSMutableString
                          stringWithString:[re stringByReplacingMatchesInString:nativePath
                                                                        options:0
                                                                          range:NSMakeRange(0, nativePath.length)
                                                                   withTemplate:value.length>0?value:@""]];
        }
    }
    relativePath = [NSMutableString stringWithFormat:@"%@;\n", relativePath];
    
    NSMutableDictionary *infoObject = [[NSMutableDictionary alloc] initWithDictionary:@{@"code": @"",
                                                                                        @"page_name": @""}];
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:nativePath]) {
                infoObject[@"code"] = info[@"code"];
                infoObject[@"page_name"] = info[@"page_name"];
                break;
            }
        }
    }
    NSData *infoData = [NSJSONSerialization dataWithJSONObject:infoObject
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *infoString = [[NSString alloc] initWithData:infoData
                                                 encoding:NSUTF8StringEncoding];
    
    NSString *initInfo = [NSString stringWithFormat:@"sugo.init = %@;\n", infoString];
    NSString *vcPath = [NSString stringWithFormat:@"sugo.current_page = '%@::' + window.location.pathname;\n", self.wkVcPath];
    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
    NSString *variables = [self jsSourceOfFileName:@"WebViewVariables"];
    
    return [[[[relativePath stringByAppendingString:initInfo]
              stringByAppendingString:vcPath]
             stringByAppendingString:bindings]
            stringByAppendingString:variables];
    
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

- (NSString *)jsWKWebViewExcute
{
    return [self jsSourceOfFileName:@"WebViewExcute"];
}

- (NSString *)jsWKWebViewSugoEnd
{
    return [self jsSourceOfFileName:@"SugoEnd"];
}



//- (NSString *)jsWKWebViewSugo
//{
//    return [self jsSourceOfFileName:@"Sugo"];
//}
//
//- (NSString *)jsWKWebViewTrack
//{
//    NSMutableString *nativePath = [[NSMutableString alloc] initWithString:self.wkWebView.URL.path];
//    NSMutableString *relativePath = [NSMutableString stringWithFormat:@"sugo.relative_path = window.location.pathname"];
//    NSDictionary *replacements = [Sugo sharedInstance].sugoConfiguration[@"ResourcesPathReplacements"];
//    if (replacements) {
//        for (NSDictionary *replacement in replacements) {
//            if ((replacement.allKeys.count <= 0)
//                || (((NSString *)replacement.allKeys.firstObject)).length <= 0) {
//                continue;
//            }
//            NSString *key = (NSString *)replacement.allKeys.firstObject;
//            NSString *value = (NSString *)replacement[key];
//            relativePath = [NSMutableString stringWithFormat:@"%@.replace(/%@/g, %@)",
//                            relativePath,
//                            key,
//                            value.length>0?value:@"''"];
//            
//        }
//        if (replacements[@"HomePath"]) {
//            NSString *key = (NSString *)((NSDictionary *)replacements[@"HomePath"]).allKeys.firstObject;
//            NSString *value = (NSString *)((NSDictionary *)replacements[@"HomePath"])[key];
//            NSRegularExpression *re = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"^%@$", key]
//                                                                           options:NSRegularExpressionAnchorsMatchLines
//                                                                             error:nil];
//            nativePath = [NSMutableString
//                          stringWithString:[re stringByReplacingMatchesInString:nativePath
//                                                                        options:0
//                                                                          range:NSMakeRange(0, nativePath.length)
//                                                                   withTemplate:value.length>0?value:@""]];
//        }
//    }
//    relativePath = [NSMutableString stringWithFormat:@"%@;", relativePath];
//    
//    NSMutableString *pn = [[NSMutableString alloc] init];
//    NSMutableString *ic = [[NSMutableString alloc] init];
//    if ([SugoPageInfos global].infos.count > 0) {
//        for (NSDictionary *info in [SugoPageInfos global].infos) {
//            if ([info[@"page"] isEqualToString:nativePath]) {
//                pn = info[@"page"];
//                ic = info[@"code"];
//                break;
//            }
//        }
//    }
//    NSMutableString *pageName = [NSMutableString stringWithFormat:@"sugo.page_name = %@;", pn.length>0?pn:@"''"];
//    NSMutableString *initCode = [NSMutableString stringWithFormat:@"sugo.init_code = %@;", ic.length>0?ic:@"''"];
//
//    NSString *wk = [self jsSourceOfFileName:@"WebViewTrack.WK"];
//    
//    return [[[relativePath stringByAppendingString:pageName]
//             stringByAppendingString:initCode]
//            stringByAppendingString:wk];
//}
//
//- (NSString *)jsWKWebViewBindingsSource
//{
//    NSString *vcPath = [NSString stringWithFormat:@"sugo.current_page = '%@::' + window.location.pathname;\n", self.wkVcPath];
//    NSString *bindings = [NSString stringWithFormat:@"sugo.h5_event_bindings = %@;\n", self.stringBindings];
//    NSString *wk = [self jsSourceOfFileName:@"WebViewBindings.WK"];
//    
//    return [[vcPath stringByAppendingString:bindings]
//            stringByAppendingString:wk];
//}
//
//- (NSString *)jsWKWebViewBindingsExcute
//{
//    return [self jsSourceOfFileName:@"WebViewBindings.excute"];
//}
//
//- (NSString *)jsWKWebViewUtils
//{
//    return [self jsSourceOfFileName:@"Utils"];
//}
//
//- (NSString *)jsWKWebViewReportSource
//{
//    return [self jsSourceOfFileName:@"WebViewReport.WK"];
//}


@end









