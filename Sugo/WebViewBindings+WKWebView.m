//
//  WebViewBindings+WKWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+WKWebView.h"
#import "Sugo.h"
#import "MPSwizzler.h"


@implementation WebViewBindings (WKWebView)

- (void)startWKWebViewBindings:(WKWebView **)webView
{
    if (!self.wkWebViewJavaScriptInjected) {
        self.wkWebViewCurrentJSSource = [self wkJavaScriptSource];
        self.wkWebViewCurrentJSExcute = [self wkJavaScriptExcute];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSExcute];
        [(*webView).configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewBindings"];
        self.wkWebViewJavaScriptInjected = YES;
        NSLog(@"WKWebView Injected");
    }
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindings"];
        self.wkWebViewJavaScriptInjected = NO;
        self.wkWebView = nil;
    }
}

- (void)updateWKWebViewBindings:(WKWebView **)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        NSMutableArray<WKUserScript *> *userScripts = [[NSMutableArray<WKUserScript *> alloc] initWithArray:(*webView).configuration.userContentController.userScripts];
        if ([userScripts containsObject:self.wkWebViewCurrentJSSource]) {
            [userScripts removeObject:self.wkWebViewCurrentJSSource];
        }
        if ([userScripts containsObject:self.wkWebViewCurrentJSExcute]) {
            [userScripts removeObject:self.wkWebViewCurrentJSExcute];
        }
        [(*webView).configuration.userContentController removeAllUserScripts];
        for (WKUserScript *userScript in userScripts) {
            [(*webView).configuration.userContentController addUserScript:userScript];
        }
        self.wkWebViewCurrentJSSource = [self wkJavaScriptSource];
        self.wkWebViewCurrentJSExcute = [self wkJavaScriptExcute];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSSource];
        [(*webView).configuration.userContentController addUserScript:self.wkWebViewCurrentJSExcute];
        NSLog(@"WKWebView Updated");
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    if ([message.body isKindOfClass:[NSDictionary class]]) {
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
            [[Sugo sharedInstance] track:storage.eventID
                               eventName:storage.eventName
                              properties:pJSON];
        }
        else
        {
            [[Sugo sharedInstance] track:storage.eventID
                               eventName:storage.eventName];
        }
        NSLog(@"HTML Event: id = %@, name = %@", storage.eventID, storage.eventName);
    }
}

- (WKUserScript *)wkJavaScriptSource
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsSource
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (WKUserScript *)wkJavaScriptExcute
{
    return [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsExcute
                                  injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                               forMainFrameOnly:YES];
}

- (NSString *)jsWKWebViewBindingsSource
{
    NSString *part1 = @"var sugo_binding = {};\n \
    sugo_binding.current_page = '";
    NSString *part2 = @"::' + window.location.pathname;\n \
    sugo_binding.h5_event_bindings = ";
    NSString *part3 = @";\n \
    sugo_binding.current_event_bindings = {};\n \
    for (var i = 0; i < sugo_binding.h5_event_bindings.length; i++) {\n \
        var b_event = sugo_binding.h5_event_bindings[i];\n \
        if (b_event.target_activity === sugo_binding.current_page) {\n \
            var key = JSON.stringify(b_event.path);\n \
            sugo_binding.current_event_bindings[key] = b_event;\n \
        }\n \
    };\n \
    sugo_binding.addEvent = function (children, event) {\n \
        children.addEventListener(event.event_type, function (e) {\n \
            var custom_props = {};\n \
            if(event.code && event.code.replace(/(^\\s*)|(\\s*$)/g, \"\") != ''){\n \
                var sugo_props = new Function(event.code);\n \
                custom_props = sugo_props();\n \
            }\n \
            custom_props.from_binding = true;\n \
            var message = {\n \
                'eventID' : event.event_id,\n \
                'eventName' : event.event_name,\n \
                'properties' : '{}'\n \
            };\n \
            window.webkit.messageHandlers.WKWebViewBindings.postMessage(message);\n \
        });\n \
    };\n \
    sugo_binding.bindEvent = function () {\n \
        var paths = Object.keys(sugo_binding.current_event_bindings);\n \
        for(var idx = 0;idx < paths.length; idx++) {\n \
            var path_str = paths[idx];\n \
            var event = sugo_binding.current_event_bindings[path_str];\n \
            var path = JSON.parse(paths[idx]).path;\n \
            if(event.similar === true){\n \
                path = path.replace(/:nth-child\\([0-9]*\\)/g, \"\");\n \
            }\n \
            var eles = document.querySelectorAll(path);\n \
            if(eles){\n \
                for(var eles_idx=0;eles_idx < eles.length; eles_idx ++){\n \
                    var ele = eles[eles_idx];\n \
                    sugo_binding.addEvent(ele, event);\n \
                }\n \
            }\n \
        }\n \
    };";
    
    return [[[[part1 stringByAppendingString:self.wkVcPath]
              stringByAppendingString:part2]
             stringByAppendingString:self.stringBindings]
            stringByAppendingString:part3];
}

- (NSString *)jsWKWebViewBindingsExcute
{
    return @"sugo_binding.bindEvent();";
}

@end









