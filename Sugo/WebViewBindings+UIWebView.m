//
//  WebViewBindings+UIWebView.m
//  Sugo
//
//  Created by Zack on 2/12/16.
//  Copyright © 2016年 Sugo. All rights reserved.
//

#import "WebViewBindings+UIWebView.h"
#import "WebViewJSExport.h"
#import "MPSwizzler.h"


@implementation WebViewBindings (UIWebView)

- (void)startUIWebViewBindings:(UIWebView *)webView
{
    void (^uiWebViewDidStartLoadBlock)(id, SEL) = ^(id webView, SEL command) {
        if (self.uiWebViewJavaScriptInjected) {
            self.uiWebViewJavaScriptInjected = NO;
            NSLog(@"UIWebView Uninjected");
        }
    };
    
    void (^uiWebViewDidFinishLoadBlock)(id, SEL) = ^(id webView, SEL command) {
        UIWebView *wv = (UIWebView *)webView;
        if (!wv
            || !wv.request.URL
            || wv.request.URL.absoluteString.length <= 0
            || wv.isLoading) {
            return;
        }
        if (!self.uiWebViewJavaScriptInjected) {
            JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            WebViewJSExport *jsExport = [[WebViewJSExport alloc] init];
            jsContext[@"WebViewJSExport"] = jsExport;
            [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
            [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
            self.uiWebViewJavaScriptInjected = YES;
            NSLog(@"UIWebView Injected");
        }
    };
    
    if (!self.uiWebViewSwizzleRunning) {
        if (webView.delegate) {
            [MPSwizzler swizzleSelector:@selector(webViewDidStartLoad:)
                                onClass:[webView.delegate class]
                              withBlock:uiWebViewDidStartLoadBlock
                                  named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler swizzleSelector:@selector(webViewDidFinishLoad:)
                                onClass:[webView.delegate class]
                              withBlock:uiWebViewDidFinishLoadBlock
                                  named:self.uiWebViewDidFinishLoadBlockName];
            self.uiWebViewSwizzleRunning = YES;
        }
    }
}

- (void)stopUIWebViewBindings:(UIWebView *)webView
{
    if (self.uiWebViewSwizzleRunning) {
        if (webView.delegate) {
            [MPSwizzler unswizzleSelector:@selector(webViewDidStartLoad:)
                                  onClass:[webView.delegate class]
                                    named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler unswizzleSelector:@selector(webViewDidFinishLoad:)
                                  onClass:[webView.delegate class]
                                    named:self.uiWebViewDidFinishLoadBlockName];
            self.uiWebViewJavaScriptInjected = NO;
            self.uiWebViewSwizzleRunning = NO;
            self.uiWebView = nil;
        }
    }
}

- (void)updateUIWebViewBindings:(UIWebView *)webView
{
    if (self.uiWebViewSwizzleRunning) {
        JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        WebViewJSExport *jsExport = [[WebViewJSExport alloc] init];
        jsContext[@"WebViewJSExport"] = jsExport;
        [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
        [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
    }
}

//- (NSString *)jsUIWebViewBindingsSource
//{
//    NSString *part1 = @"var sugo_bind={};\n \
//    sugo_bind.current_page ='";
//    NSString *part2 = @"::' + window.location.pathname;\n \
//    sugo_bind.h5_event_bindings = ";
//    NSString *part3 = @";\n \
//    sugo_bind.current_event_bindings = {};\n \
//    for(var i=0;i<sugo_bind.h5_event_bindings.length;i++){\n \
//    \tvar b_event = sugo_bind.h5_event_bindings[i];\n \
//    \tif(b_event.target_activity === sugo_bind.current_page){\n \
//    \t\tvar key = JSON.stringify(b_event.path);\n \
//    \t\tsugo_bind.current_event_bindings[key] = b_event;\n \
//    \t}\n \
//    };\n \
//    sugo_bind.get_node_name = function(node){\n \
//    \tvar path = '';\n \
//    \tvar name = node.localName;\n \
//    \tif(name == 'script'){return '';}\n \
//    \tif(name == 'link'){return '';}\n \
//    \tpath = name;\n \
//    \tid = node.id;\n \
//    \tif(id && id.length>0){\n \
//    \t\tpath += '#' + id;\n \
//    \t}\n \
//    \treturn path;\n \
//    };\n \
//    sugo_bind.bindChildNode = function (childrens, jsonArry, parent_path){\n \
//    \t\tvar index_map={};\n \
//    \t\tfor(var i=0;i<childrens.length;i++){\n \
//    \t\t\tvar children = childrens[i];\n \
//    \t\t\tvar node_name = sugo_bind.get_node_name(children);\n \
//    \t\t\tif (node_name == ''){continue;}\n \
//    \t\t\tif(index_map[node_name] == null){\n \
//    \t\t\t\tindex_map[node_name] = 0;\n \
//    \t\t\t}else{\n \
//    \t\t\t\tindex_map[node_name] = index_map[node_name]  + 1;\n \
//    \t\t\t}\n \
//    \t\t\tvar htmlNode={};\n \
//    \t\t\tvar path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n \
//    \t\t\thtmlNode.path=path;\t\t\t\n \
//    \t\t\tvar b_event = sugo_bind.current_event_bindings[JSON.stringify(htmlNode)];\n \
//    \tif(b_event){\n \
//    \t\t\t\tvar event = JSON.parse(JSON.stringify(b_event));\n \
//    \t\t\t\tchildren.addEventListener(event.event_type, function(e){\n \
//    \t\t\t\t\tWebViewJSExport.eventWithIdNameProperties(event.event_id, event.event_name, '{}');\n \
//    \t\t\t\t});\n \
//    \t}\n \
//    \t\t\tif(children.children){\n \
//    \t\t\t\tsugo_bind.bindChildNode(children.children, jsonArry, path);\n \
//    \t\t\t}\n \
//    \t\t}\n \
//    }; \
//    sugo_bind.bindEvent = function(){\n \
//    \tvar jsonArry=[];\n \
//    \tvar body = document.getElementsByTagName('body')[0];\n \
//    \tvar childrens = body.children;\n \
//    \tvar parent_path='';\n \
//    \tsugo_bind.bindChildNode(childrens, jsonArry, parent_path);\n \
//    };";
//    
//    return [[[[part1 stringByAppendingString:self.vcPath]
//              stringByAppendingString:part2]
//             stringByAppendingString:self.stringBindings]
//            stringByAppendingString:part3];
//}
//
- (NSString *)jsUIWebViewBindingsExcute
{
    return @"sugo_bind.bindEvent();";
}

@end










