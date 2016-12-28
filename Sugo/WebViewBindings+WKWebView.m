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

- (void)bindWKWebView:(WKWebView *)webView
{
    self.wkWebView = webView;
    if (!self.wkWebViewJavaScriptInjected) {
        UIResponder *responder = webView;
        while (responder.nextResponder) {
            responder = responder.nextResponder;
            if ([responder isKindOfClass:[UIViewController class]]) {
                self.vcPath = NSStringFromClass(responder.classForCoder);
                break;
            }
        }
        
        WKUserScript *jsSource = [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsSource
                                                        injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                     forMainFrameOnly:true];
        WKUserScript *jsExcute = [[WKUserScript alloc] initWithSource:self.jsWKWebViewBindingsExcute
                                                        injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                     forMainFrameOnly:true];
        [self.wkWebView.configuration.userContentController addUserScript:jsSource];
        [self.wkWebView.configuration.userContentController addUserScript:jsExcute];
        [self.wkWebView.configuration.userContentController addScriptMessageHandler:self
                                                                               name:@"WKWebViewBindings"];
        [self.wkWebView evaluateJavaScript:self.jsWKWebViewBindingsSource completionHandler:nil];
        [self.wkWebView evaluateJavaScript:self.jsWKWebViewBindingsExcute completionHandler:nil];
        self.wkWebViewJavaScriptInjected = true;
    }
}

- (void)stopWKWebViewBindings:(WKWebView *)webView
{
    if (self.wkWebViewJavaScriptInjected) {
        if (webView.navigationDelegate) {
            [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewBindings"];
            self.wkWebViewJavaScriptInjected = false;
        }
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name  isEqual: @"WKWebViewBindings"]) {
        NSDictionary *body = (NSDictionary *)message.body;
        if (body) {
            WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
            storage.eventID = (NSString *)body[@"properties"];
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
        }
    }
}

- (NSString *)jsWKWebViewBindingsSource
{
    NSString *part1 = @"var sugo_bind={};\n \
    sugo_bind.current_page ='";
    NSString *part2 = @"::' + window.location.pathname;\n \
    sugo_bind.h5_event_bindings = ";
    NSString *part3 = @";\n \
    sugo_bind.current_event_bindings = {};\n \
    for(var i=0;i<sugo_bind.h5_event_bindings.length;i++){\n \
    \tvar b_event = sugo_bind.h5_event_bindings[i];\n \
    \tif(b_event.target_activity === sugo_bind.current_page){\n \
    \t\tvar key = JSON.stringify(b_event.path);\n \
    \t\tsugo_bind.current_event_bindings[key] = b_event;\n \
    \t}\n \
    };\n \
    sugo_bind.get_node_name = function(node){\n \
    \tvar path = '';\n \
    \tvar name = node.localName;\n \
    \tif(name == 'script'){return '';}\n \
    \tif(name == 'link'){return '';}\n \
    \tpath = name;\n \
    \tid = node.id;\n \
    \tif(id && id.length>0){\n \
    \t\tpath += '#' + id;\n \
    \t}\n \
    \treturn path;\n \
    };\n \
    sugo_bind.bindChildNode = function (childrens, jsonArry, parent_path){\n \
    \t\tvar index_map={};\n \
    \t\tfor(var i=0;i<childrens.length;i++){\n \
    \t\t\tvar children = childrens[i];\n \
    \t\t\tvar node_name = sugo_bind.get_node_name(children);\n \
    \t\t\tif (node_name == ''){continue;}\n \
    \t\t\tif(index_map[node_name] == null){\n \
    \t\t\t\tindex_map[node_name] = 0;\n \
    \t\t\t}else{\n \
    \t\t\t\tindex_map[node_name] = index_map[node_name]  + 1;\n \
    \t\t\t}\n \
    \t\t\tvar htmlNode={};\n \
    \t\t\tvar path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n \
    \t\t\thtmlNode.path=path;\t\t\t\n \
    \t\t\tvar b_event = sugo_bind.current_event_bindings[JSON.stringify(htmlNode)];\n \
    \tif(b_event){\n \
    \t\t\t\tvar event = JSON.parse(JSON.stringify(b_event));\n \
    \t\t\t\tchildren.addEventListener(event.event_type, function(e){\n \
    var message = {\n \
    \t\t\t\t'eventID' : event.event_id,\n \
    \t\t\t\t'eventName' : event.event_name,\n \
    \t\t\t\t'properties' : '{}'\n \
    \t\t\t\t};\n \
    window.webkit.messageHandlers.WKWebViewBindings.postMessage(message);\n \
    \t\t\t\t});\n \
    \t}\n \
    \t\t\tif(children.children){\n \
    \t\t\t\tsugo_bind.bindChildNode(children.children, jsonArry, path);\n \
    \t\t\t}\n \
    \t\t}\n \
    }; \
    sugo_bind.bindEvent = function(){\n \
    \tvar jsonArry=[];\n \
    \tvar body = document.getElementsByTagName('body')[0];\n \
    \tvar childrens = body.children;\n \
    \tvar parent_path='';\n \
    \tsugo_bind.bindChildNode(childrens, jsonArry, parent_path);\n \
    };";
    
    return [[[[part1 stringByAppendingString:self.vcPath]
              stringByAppendingString:part2]
             stringByAppendingString:self.stringBindings]
            stringByAppendingString:part3];
}

- (NSString *)jsWKWebViewBindingsExcute
{
    return @"sugo_bind.bindEvent();";
}

@end









