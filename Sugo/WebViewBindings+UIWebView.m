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

- (void)startUIWebViewBindings:(UIWebView **)webView
{
    void (^uiWebViewDidStartLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        if (self.uiWebViewJavaScriptInjected) {
            self.uiWebViewJavaScriptInjected = NO;
            NSLog(@"UIWebView Uninjected");
        }
    };
    
    void (^uiWebViewDidFinishLoadBlock)(id, SEL, id) = ^(id viewController, SEL command, id webView) {
        if (![webView isKindOfClass:[UIWebView class]]
            || ((UIWebView *)webView).request.URL.absoluteString.length <= 0
            || ((UIWebView *)webView).isLoading) {
            return;
        }
        if (!self.uiWebViewJavaScriptInjected) {
            JSContext *jsContext = [(UIWebView *)webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
            jsContext[@"WebViewJSExport"] = [WebViewJSExport class];
            [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
            [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
            self.uiWebViewJavaScriptInjected = YES;
            NSLog(@"UIWebView Injected");
        }
    };
    
    if (!self.uiWebViewSwizzleRunning) {
        if ((*webView).delegate) {
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                onClass:[(*webView).delegate class]
                              withBlock:uiWebViewDidStartLoadBlock
                                  named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler swizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                onClass:[(*webView).delegate class]
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
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidStartLoad:")
                                  onClass:[webView.delegate class]
                                    named:self.uiWebViewDidStartLoadBlockName];
            [MPSwizzler unswizzleSelector:NSSelectorFromString(@"webViewDidFinishLoad:")
                                  onClass:[webView.delegate class]
                                    named:self.uiWebViewDidFinishLoadBlockName];
            self.uiWebViewJavaScriptInjected = NO;
            self.uiWebViewSwizzleRunning = NO;
            self.uiWebView = nil;
        }
    }
}

- (void)updateUIWebViewBindings:(UIWebView **)webView
{
    if (self.uiWebViewSwizzleRunning) {
        JSContext *jsContext = [(*webView) valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
        WebViewJSExport *jsExport = [[WebViewJSExport alloc] init];
        jsContext[@"WebViewJSExport"] = jsExport;
        [jsContext evaluateScript:[self jsUIWebViewBindingsSource]];
        [jsContext evaluateScript:[self jsUIWebViewBindingsExcute]];
    }
}

- (NSString *)jsUIWebViewBindingsSource
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
            WebViewJSExport.eventWithIdNameProperties(event.event_id, event.event_name, JSON.stringify(custom_props));\n \
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
    
    return [[[[part1 stringByAppendingString:self.uiVcPath]
              stringByAppendingString:part2]
             stringByAppendingString:self.stringBindings]
            stringByAppendingString:part3];
}

- (NSString *)jsUIWebViewBindingsExcute
{
    return @"sugo_binding.bindEvent();";
}

@end










