//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "UIView+MPHelpers.h"
#import "MPClassDescription.h"
#import "MPEnumDescription.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"
#import "MPObjectSerializerContext.h"
#import "MPPropertyDescription.h"
#import "NSInvocation+MPHelpers.h"
#import "WebViewInfoStorage.h"
#import "WebViewJSExport.h"


@interface MPObjectSerializer (WebViewSerializer) <WKScriptMessageHandler>

- (NSString *)jsUIWebViewReportSource;
- (NSString *)jsUIWebViewReportExcute;
- (NSString *)jsWKWebViewReport;

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView;
- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView;

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

@implementation MPObjectSerializer

{
    MPObjectSerializerConfig *_configuration;
    MPObjectIdentityProvider *_objectIdentityProvider;
}

- (instancetype)initWithConfiguration:(MPObjectSerializerConfig *)configuration objectIdentityProvider:(MPObjectIdentityProvider *)objectIdentityProvider
{
    self = [super init];
    if (self) {
        _configuration = configuration;
        _objectIdentityProvider = objectIdentityProvider;
    }

    return self;
}

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject
{
    NSParameterAssert(rootObject != nil);

    MPObjectSerializerContext *context = [[MPObjectSerializerContext alloc] initWithRootObject:rootObject];

    while ([context hasUnvisitedObjects])
    {
        [self visitObject:[context dequeueUnvisitedObject] withContext:context];
    }

    return @{
            @"objects": [context allSerializedObjects],
            @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    };
}

- (void)visitObject:(NSObject *)object withContext:(MPObjectSerializerContext *)context
{
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);

    [context addVisitedObject:object];

    NSMutableDictionary *propertyValues = [NSMutableDictionary dictionary];

    MPClassDescription *classDescription = [self classDescriptionForObject:object];
    if (classDescription) {
        for (MPPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
            if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];
                propertyValues[propertyDescription.name] = propertyValue ?: [NSNull null];
            }
        }
    }

    NSMutableArray *delegateMethods = [NSMutableArray array];
    id delegate;
    SEL delegateSelector = @selector(delegate);

    if ([classDescription delegateInfos].count > 0 && [object respondsToSelector:delegateSelector]) {
        delegate = ((id (*)(id, SEL))[object methodForSelector:delegateSelector])(object, delegateSelector);
        for (MPDelegateInfo *delegateInfo in [classDescription delegateInfos]) {
            if ([delegate respondsToSelector:NSSelectorFromString(delegateInfo.selectorName)]) {
                [delegateMethods addObject:delegateInfo.selectorName];
            }
        }
    }

    NSMutableDictionary *serializedObject = (NSMutableDictionary *)@{
        @"id": [_objectIdentityProvider identifierForObject:object],
        @"class": [self classHierarchyArrayForObject:object],
        @"properties": propertyValues,
        @"delegate": @{
                @"class": delegate ? NSStringFromClass([delegate class]) : @"",
                @"selectors": delegateMethods
            }
    };
    
//    if ([object isKindOfClass:[UIWebView class]]) {
//        serializedObject[@"htmlPage"] = [self getUIWebViewHTMLInfoFrom:(UIWebView *)object];
//    } else if ([object isKindOfClass:[WKWebView class]]) {
//        serializedObject[@"htmlPage"] = [self getWKWebViewHTMLInfoFrom:(WKWebView *)object];
//    }

    [context addSerializedObject:serializedObject];
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object
{
    NSMutableArray *classHierarchy = [NSMutableArray array];

    Class aClass = [object class];
    while (aClass)
    {
        [classHierarchy addObject:NSStringFromClass(aClass)];
        aClass = [aClass superclass];
    }

    return [classHierarchy copy];
}

- (NSArray *)allValuesForType:(NSString *)typeName
{
    NSParameterAssert(typeName != nil);

    MPTypeDescription *typeDescription = [_configuration typeWithName:typeName];
    if ([typeDescription isKindOfClass:[MPEnumDescription class]]) {
        MPEnumDescription *enumDescription = (MPEnumDescription *)typeDescription;
        return [enumDescription allValues];
    }

    return @[];
}

- (NSArray *)parameterVariationsForPropertySelector:(MPPropertySelectorDescription *)selectorDescription
{
    NSAssert(selectorDescription.parameters.count <= 1, @"Currently only support selectors that take 0 to 1 arguments.");

    NSMutableArray *variations = [NSMutableArray array];

    // TODO: write an algorithm that generates all the variations of parameter combinations.
    if (selectorDescription.parameters.count > 0) {
        MPPropertySelectorParameterDescription *parameterDescription = selectorDescription.parameters[0];
        for (id value in [self allValuesForType:parameterDescription.type]) {
            [variations addObject:@[ value ]];
        }
    } else {
        // An empty array of parameters (for methods that have no parameters).
        [variations addObject:@[]];
    }

    return [variations copy];
}

- (id)instanceVariableValueForObject:(id)object propertyDescription:(MPPropertyDescription *)propertyDescription
{
    NSParameterAssert(object != nil);
    NSParameterAssert(propertyDescription != nil);

    Ivar ivar = class_getInstanceVariable([object class], [propertyDescription.name UTF8String]);
    if (ivar) {
        const char *objCType = ivar_getTypeEncoding(ivar);

        ptrdiff_t ivarOffset = ivar_getOffset(ivar);
        const void *objectBaseAddress = (__bridge const void *)object;
        const void *ivarAddress = (((const uint8_t *)objectBaseAddress) + ivarOffset);

        switch (objCType[0])
        {
            case _C_ID:       return object_getIvar(object, ivar);
            case _C_CHR:      return @(*((char *)ivarAddress));
            case _C_UCHR:     return @(*((unsigned char *)ivarAddress));
            case _C_SHT:      return @(*((short *)ivarAddress));
            case _C_USHT:     return @(*((unsigned short *)ivarAddress));
            case _C_INT:      return @(*((int *)ivarAddress));
            case _C_UINT:     return @(*((unsigned int *)ivarAddress));
            case _C_LNG:      return @(*((long *)ivarAddress));
            case _C_ULNG:     return @(*((unsigned long *)ivarAddress));
            case _C_LNG_LNG:  return @(*((long long *)ivarAddress));
            case _C_ULNG_LNG: return @(*((unsigned long long *)ivarAddress));
            case _C_FLT:      return @(*((float *)ivarAddress));
            case _C_DBL:      return @(*((double *)ivarAddress));
            case _C_BOOL:     return @(*((_Bool *)ivarAddress));
            case _C_SEL:      return NSStringFromSelector(*((SEL*)ivarAddress));
            default:
                NSAssert(NO, @"Currently unsupported return type!");
                break;
        }
    }

    return nil;
}

- (NSInvocation *)invocationForObject:(id)object withSelectorDescription:(MPPropertySelectorDescription *)selectorDescription
{
    NSUInteger __unused parameterCount = selectorDescription.parameters.count;

    SEL aSelector = NSSelectorFromString(selectorDescription.selectorName);
    NSAssert(aSelector != nil, @"Expected non-nil selector!");

    NSMethodSignature *methodSignature = [object methodSignatureForSelector:aSelector];
    NSInvocation *invocation = nil;

    if (methodSignature) {
        NSAssert(methodSignature.numberOfArguments == (parameterCount + 2), @"Unexpected number of arguments!");

        invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        invocation.selector = aSelector;
    }
    return invocation;
}

- (id)propertyValue:(id)propertyValue propertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{
    if (propertyValue != nil) {
        if ([context isVisitedObject:propertyValue]) {
            return [_objectIdentityProvider identifierForObject:propertyValue];
        }
        else if ([self isNestedObjectType:propertyDescription.type])
        {
            [context enqueueUnvisitedObject:propertyValue];
            return [_objectIdentityProvider identifierForObject:propertyValue];
        }
        else if ([propertyValue isKindOfClass:[NSArray class]] || [propertyValue isKindOfClass:[NSSet class]])
        {
            NSMutableArray *arrayOfIdentifiers = [NSMutableArray array];
            for (id value in propertyValue) {
                if ([context isVisitedObject:value] == NO) {
                    [context enqueueUnvisitedObject:value];
                }

                [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
            }
            propertyValue = [arrayOfIdentifiers copy];
        }
    }

    return [propertyDescription.valueTransformer transformedValue:propertyValue];
}

- (id)propertyValueForObject:(NSObject *)object withPropertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{
    NSMutableArray *values = [NSMutableArray array];

    MPPropertySelectorDescription *selectorDescription = propertyDescription.getSelectorDescription;

    if (propertyDescription.useKeyValueCoding) {
        // the "fast" (also also simple) path is to use KVC
        id valueForKey = [object valueForKey:selectorDescription.selectorName];

        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context];

        NSDictionary *valueDictionary = @{
                @"value": (value ?: [NSNull null])
        };

        [values addObject:valueDictionary];
    }
    else if (propertyDescription.useInstanceVariableAccess)
    {
        id valueForIvar = [self instanceVariableValueForObject:object propertyDescription:propertyDescription];

        id value = [self propertyValue:valueForIvar
                   propertyDescription:propertyDescription
                               context:context];

        NSDictionary *valueDictionary = @{
            @"value": (value ?: [NSNull null])
        };

        [values addObject:valueDictionary];
    } else {
        // the "slow" NSInvocation path. Required in order to invoke methods that take parameters.
        NSInvocation *invocation = [self invocationForObject:object withSelectorDescription:selectorDescription];
        if (invocation) {
            NSArray *parameterVariations = [self parameterVariationsForPropertySelector:selectorDescription];

            for (NSArray *parameters in parameterVariations) {
                [invocation mp_setArgumentsFromArray:parameters];
                [invocation invokeWithTarget:object];

                id returnValue = [invocation mp_returnValue];

                id value = [self propertyValue:returnValue
                           propertyDescription:propertyDescription
                                       context:context];

                NSDictionary *valueDictionary = @{
                    @"where": @{ @"parameters": parameters },
                    @"value": (value ?: [NSNull null])
                };

                [values addObject:valueDictionary];
            }
        }
    }

    return @{@"values": values};
}

- (BOOL)isNestedObjectType:(NSString *)typeName
{
    return [_configuration classWithName:typeName] != nil;
}

- (MPClassDescription *)classDescriptionForObject:(NSObject *)object
{
    NSParameterAssert(object != nil);

    Class aClass = [object class];
    while (aClass != nil)
    {
        MPClassDescription *classDescription = [_configuration classWithName:NSStringFromClass(aClass)];
        if (classDescription) {
            return classDescription;
        }

        aClass = [aClass superclass];
    }
    return nil;
}

@end

@implementation MPObjectSerializer (WebViewSerializer)

//- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView
//{
//    JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//    WebViewJSExport *jsExport = [[WebViewJSExport alloc] init];
//    jsContext[@"WebViewJSExport"] = jsExport;
//    [jsContext evaluateScript:self.jsUIWebViewReportSource];
//    [jsContext evaluateScript:self.jsUIWebViewReportExcute];
//    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
//    return @{
//             @"url": storage.path,
//             @"clientWidth": storage.width,
//             @"clientHeight": storage.height,
//             @"nodes": storage.nodes
//             };
//}
//
//- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView
//{
//    WKUserScript *jsReportScript = [[WKUserScript alloc] initWithSource:self.jsWKWebViewReport injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
//    if (![webView.configuration.userContentController.userScripts containsObject:jsReportScript]) {
//        [webView.configuration.userContentController addUserScript:jsReportScript];
//    }
//    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewReporter"];
//    [webView.configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewReporter"];
//    [webView evaluateJavaScript:self.jsWKWebViewReport completionHandler:nil];
//    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
//    return @{
//             @"url": storage.path,
//             @"clientWidth": storage.width,
//             @"clientHeight": storage.height,
//             @"nodes": storage.nodes
//             };
//}
//
//- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
//{
//    if ([message.name  isEqual: @"WKWebViewReporter"])
//    {
//        NSDictionary *body = (NSDictionary *)message.body;
//        WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
//        if (body[@"path"])
//        {
//            storage.path = (NSString *)body[@"path"];
//        }
//        if (body[@"clientWidth"])
//        {
//            storage.width = (NSString *)body[@"clientWidth"];
//        }
//        if (body[@"clientHeight"])
//        {
//            storage.height = (NSString *)body[@"clientHeight"];
//        }
//        if (body[@"nodes"])
//        {
//            storage.nodes = (NSString *)body[@"nodes"];
//        }
//    }
//}
//
//- (NSString *)jsUIWebViewReportSource
//{
//    return @"var sugo_report={};\n \
//    \tsugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n \
//    \tsugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n \
//    \tsugo_report.isElementInViewport = function(rect) {\n \
//    \t        return (\n \
//    \t                rect.top >= 0 &&\n \
//    \t                rect.left >= 0 &&\n \
//    \t                rect.bottom <= sugo_report.clientHeight && \n \
//    \t                rect.right <= sugo_report.clientWidth\n \
//    \t        );\n \
//    \t};\n \
//    \tsugo_report.get_node_name = function(node){\n \
//    \t\tvar path = '';\n \
//    \t\tvar name = node.localName;\n \
//    \t\tif(name == 'script'){return '';}\n \
//    \t\tif(name == 'link'){return '';}\n \
//    \t\tpath = name;\n \
//    \t\tid = node.id;\n \
//    \t\tif(id && id.length>0){\n \
//    \t\t\tpath += '#' + id;\n \
//    \t\t}\n \
//    \t\treturn path;\n \
//    \t};\n \
//    \tsugo_report.reportChildNode = function(childrens, jsonArry, parent_path){\n \
//    \t\t\tvar index_map={};\n \
//    \t\t\tfor(var i=0;i<childrens.length;i++){\n \
//    \t\t\t\tvar children = childrens[i];\n \
//    \t\t\t\tvar node_name = sugo_report.get_node_name(children);\n \
//    \t\t\t\tif (node_name == ''){ continue;}\n \
//    \t\t\t\tif(index_map[node_name] == null){\n \
//    \t\t\t\t\tindex_map[node_name] = 0;\n \
//    \t\t\t\t}else{\n \
//    \t\t\t\t\tindex_map[node_name] = index_map[node_name]  + 1;\n \
//    \t\t\t\t}\n \
//    \t\t\t\tvar htmlNode={};\n \
//    \t\t\tvar path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n \
//    \t\thtmlNode.path=path; \
//    \t\t\t\tvar rect = children.getBoundingClientRect();\n \
//    \t\t\t\tif(sugo_report.isElementInViewport(rect) == true){ \n \
//    \t\t\t\t\thtmlNode.rect=rect;\n \
//    \t\t\t\t\tjsonArry.push(htmlNode);\n \
//    \t\t\t\t}\n \
//    \t\t\t\tif(children.children){\n \
//    \t\t\t\t\tsugo_report.reportChildNode(children.children, jsonArry, path);\n \
//    \t\t\t\t}\n \
//    \t\t\t}\n \
//    \t};\n \
//    \tsugo_report.reportNodes = function(){\n \
//    \t\tvar jsonArry=[];\n \
//    \t\tvar body = document.getElementsByTagName('body')[0];\n \
//    \t\tvar childrens = body.children;\n \
//    \t\tvar parent_path='';\n \
//    \t\tsugo_report.reportChildNode(childrens, jsonArry, parent_path);\n \
//    \t\tWebViewJSExport.infoWithPathNodesWidthHeight(window.location.pathname, JSON.stringify(jsonArry), sugo_report.clientWidth, sugo_report.clientHeight);\n \
//    \t};";
//}
//
//- (NSString *)jsUIWebViewReportExcute
//{
//    return @"sugo_report.reportNodes();";
//}
//
//- (NSString *)jsWKWebViewReport
//{
//    return @"var sugo_report={};\n \
//    \tsugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n \
//    \tsugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n \
//    \tsugo_report.isElementInViewport = function(rect) {\n \
//    \t        return (\n \
//    \t                rect.top >= 0 &&\n \
//    \t                rect.left >= 0 &&\n \
//    \t                rect.bottom <= sugo_report.clientHeight && \n \
//    \t                rect.right <= sugo_report.clientWidth\n \
//    \t        );\n \
//    \t};\n \
//    \tsugo_report.get_node_name = function(node){\n \
//    \t\tvar path = '';\n \
//    \t\tvar name = node.localName;\n \
//    \t\tif(name == 'script'){return '';}\n \
//    \t\tif(name == 'link'){return '';}\n \
//    \t\tpath = name;\n \
//    \t\tid = node.id;\n \
//    \t\tif(id && id.length>0){\n \
//    \t\t\tpath += '#' + id;\n \
//    \t\t}\n \
//    \t\treturn path;\n \
//    \t};\n \
//    \tsugo_report.reportChildNode = function(childrens, jsonArry, parent_path){\n \
//    \t\t\tvar index_map={};\n \
//    \t\t\tfor(var i=0;i<childrens.length;i++){\n \
//    \t\t\t\tvar children = childrens[i];\n \
//    \t\t\t\tvar node_name = sugo_report.get_node_name(children);\n \
//    \t\t\t\tif (node_name == ''){ continue;}\n \
//    \t\t\t\tif(index_map[node_name] == null){\n \
//    \t\t\t\t\tindex_map[node_name] = 0;\n \
//    \t\t\t\t}else{\n \
//    \t\t\t\t\tindex_map[node_name] = index_map[node_name]  + 1;\n \
//    \t\t\t\t}\n \
//    \t\t\t\tvar htmlNode={};\n \
//    \t\t\tvar path=parent_path + '/' + node_name + '[' + index_map[node_name] + ']';\n \
//    \t\thtmlNode.path=path; \
//    \t\t\t\tvar rect = children.getBoundingClientRect();\n \
//    \t\t\t\tif(sugo_report.isElementInViewport(rect) == true){ \n \
//    \t\t\t\t\thtmlNode.rect=rect;\n \
//    \t\t\t\t\tjsonArry.push(htmlNode);\n \
//    \t\t\t\t}\n \
//    \t\t\t\tif(children.children){\n \
//    \t\t\t\t\tsugo_report.reportChildNode(children.children, jsonArry, path);\n \
//    \t\t\t\t}\n \
//    \t\t\t}\n \
//    \t};\n \
//    \tsugo_report.reportNodes = function(){\n \
//    \t\tvar jsonArry=[];\n \
//    \t\tvar body = document.getElementsByTagName('body')[0];\n \
//    \t\tvar childrens = body.children;\n \
//    \t\tvar parent_path='';\n \
//    \t\tsugo_report.reportChildNode(childrens, jsonArry, parent_path);\n \
//    \t\tvar message = {\n \
//    \t\t\t\t'path' : window.location.pathname,\n \
//    \t\t\t\t'clientWidth' : sugo_report.clientWidth,\n \
//    \t\t\t\t'clientHeight' : sugo_report.clientHeight,\n \
//    \t\t\t\t'nodes' : JSON.stringify(jsonArry)\n \
//    \t\t\t\t};\n \
//    \t\twindow.webkit.messageHandlers.WKWebViewReporter.postMessage(message);\n \
//    \t};\n \
//    \tsugo_report.reportNodes();";
//}

@end









