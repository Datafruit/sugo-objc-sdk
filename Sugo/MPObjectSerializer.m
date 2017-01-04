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
- (NSString *)jsWebViewUtils;

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

    NSMutableDictionary *serializedObject = [[NSMutableDictionary alloc]
                                             initWithDictionary:@{
                                                                  @"id": [_objectIdentityProvider identifierForObject:object],
                                                                  @"class": [self classHierarchyArrayForObject:object],
                                                                  @"properties": propertyValues,
                                                                  @"delegate": @{
                                                                          @"class": delegate ? NSStringFromClass([delegate class]) : @"",
                                                                          @"selectors": delegateMethods
                                                                          }
                                                                  }];
    if ([object isKindOfClass:[UIWebView class]]) {
        [serializedObject setObject:[self getUIWebViewHTMLInfoFrom:(UIWebView *)object]
                             forKey:@"htmlPage"];
    } else if ([object isKindOfClass:[WKWebView class]]) {
        [serializedObject setObject:[self getWKWebViewHTMLInfoFrom:(WKWebView *)object]
                             forKey:@"htmlPage"];
    }

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

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView
{
    JSContext *jsContext = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    jsContext[@"WebViewJSExport"] = [WebViewJSExport class]; //jsExport;
    [jsContext evaluateScript:self.jsWebViewUtils];
    [jsContext evaluateScript:self.jsUIWebViewReportSource];
    [jsContext evaluateScript:self.jsUIWebViewReportExcute];
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    return @{
             @"url": storage.path,
             @"clientWidth": storage.width,
             @"clientHeight": storage.height,
             @"nodes": storage.nodes
             };
}

- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView
{
    WKUserScript *jsUtilsScript = [[WKUserScript alloc] initWithSource:self.jsWebViewUtils
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                       forMainFrameOnly:YES];
    WKUserScript *jsReportScript = [[WKUserScript alloc] initWithSource:self.jsWKWebViewReport
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                       forMainFrameOnly:YES];
    
    if (![webView.configuration.userContentController.userScripts containsObject:jsUtilsScript]) {
        [webView.configuration.userContentController addUserScript:jsUtilsScript];
    }
    if (![webView.configuration.userContentController.userScripts containsObject:jsReportScript]) {
        [webView.configuration.userContentController addUserScript:jsReportScript];
    }
    [webView.configuration.userContentController removeScriptMessageHandlerForName:@"WKWebViewReporter"];
    [webView.configuration.userContentController addScriptMessageHandler:self name:@"WKWebViewReporter"];
    [webView evaluateJavaScript:self.jsWKWebViewReport completionHandler:nil];
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    return @{
             @"url": storage.path,
             @"clientWidth": storage.width,
             @"clientHeight": storage.height,
             @"nodes": storage.nodes
             };
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name  isEqual: @"WKWebViewReporter"])
    {
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
}

- (NSString *)jsUIWebViewReportSource
{
    return @"var sugo_report = {};\n \
    sugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n \
    sugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n \
    sugo_report.isElementInViewport = function (rect) {\n \
      return (\n \
          rect.top >= 0 &&\n \
          rect.left >= 0 &&\n \
          rect.bottom <= sugo_report.clientHeight &&\n \
          rect.right <= sugo_report.clientWidth\n \
      );\n \
    };\n \
    sugo_report.reportChildNode = function (childrens, jsonArry, parent_path, type) {\n \
      var index_map = {};\n \
      for (var i = 0; i < childrens.length; i++) {\n \
        var children = childrens[i];\n \
        var path = UTILS.cssPath(children);\n \
        var htmlNode = {};\n \
        htmlNode.path = path;\n \
        var rect = children.getBoundingClientRect();\n \
        if (sugo_report.isElementInViewport(rect) == true) {\n \
            var temp_rect = {\n \
                    top: rect.top,\n \
                    left: rect.left,\n \
                    width: rect.width,\n \
                    height: rect.height\n \
                };\n \
            htmlNode.rect = temp_rect;\n \
            jsonArry.push(htmlNode); \
    }\n \
        if (children.children) {\n \
          sugo_report.reportChildNode(children.children, jsonArry, path, type);\n \
        }\n \
      }\n \
    };\n \
    sugo_report.reportNodes = function () {\n \
      var jsonArry = [];\n \
      var body = document.getElementsByTagName('body')[0];\n \
      var childrens = body.children;\n \
      var parent_path = '';\n \
      sugo_report.reportChildNode(childrens, jsonArry, parent_path, 'report');\n \
    \n \
      WebViewJSExport.infoWithPathNodesWidthHeight(window.location.pathname, JSON.stringify(jsonArry), sugo_report.clientWidth, sugo_report.clientHeight);\n \
    };\n";
}

- (NSString *)jsUIWebViewReportExcute
{
    return @"sugo_report.reportNodes();";
}

- (NSString *)jsWKWebViewReport
{
    return @"var sugo_report = {};\n \
    sugo_report.clientWidth = (window.innerWidth || document.documentElement.clientWidth);\n \
    sugo_report.clientHeight = (window.innerHeight || document.documentElement.clientHeight);\n \
    sugo_report.isElementInViewport = function (rect) {\n \
        return (\n \
            rect.top >= 0 &&\n \
            rect.left >= 0 &&\n \
            rect.bottom <= sugo_report.clientHeight &&\n \
            rect.right <= sugo_report.clientWidth\n \
        );\n \
    };\n \
    sugo_report.reportChildNode = function (childrens, jsonArry, parent_path, type) {\n \
        var index_map = {};\n \
        for (var i = 0; i < childrens.length; i++) {\n \
            var children = childrens[i];\n \
            var path = UTILS.cssPath(children);\n \
            var htmlNode = {};\n \
            htmlNode.path = path;\n \
            var rect = children.getBoundingClientRect();\n \
            if (sugo_report.isElementInViewport(rect) == true) {\n \
                var temp_rect = {\n \
                    top: rect.top,\n \
                    left: rect.left,\n \
                    width: rect.width,\n \
                    height: rect.height\n \
                };\n \
            htmlNode.rect = temp_rect;\n \
            jsonArry.push(htmlNode); \
        }\n \
            if (children.children) {\n \
                sugo_report.reportChildNode(children.children, jsonArry, path, type);\n \
            }\n \
        }\n \
    };\n \
    sugo_report.reportNodes = function () {\n \
        var jsonArry = [];\n \
        var body = document.getElementsByTagName('body')[0];\n \
        var childrens = body.children;\n \
        var parent_path = '';\n \
        sugo_report.reportChildNode(childrens, jsonArry, parent_path, 'report');\n \
        \n \
        var message = {\n \
            'path' : window.location.pathname,\n \
            'clientWidth' : sugo_report.clientWidth,\n \
            'clientHeight' : sugo_report.clientHeight,\n \
            'nodes' : JSON.stringify(jsonArry)\n \
        };\n \
        window.webkit.messageHandlers.WKWebViewReporter.postMessage(message);\n \
    };\n \
    sugo_report.reportNodes();";
}

- (NSString *)jsWebViewUtils
{
    return @"var UTILS = {};\n \
    UTILS.cssPath = function(node, optimized)\n \
    {\n \
        if (node.nodeType !== Node.ELEMENT_NODE)\n \
            return '';\n \
        var steps = [];\n \
        var contextNode = node;\n \
        while (contextNode) {\n \
            var step = UTILS._cssPathStep(contextNode, !!optimized, contextNode === node);\n \
            if (!step)\n \
                break; \n \
            steps.push(step);\n \
            if (step.optimized)\n \
                break;\n \
            contextNode = contextNode.parentNode;\n \
        }\n \
        steps.reverse();\n \
        return steps.join(' > ');\n \
    };\n \
    UTILS._cssPathStep = function(node, optimized, isTargetNode)\n \
    {\n \
        if (node.nodeType !== Node.ELEMENT_NODE)\n \
            return null;\n \
     \n \
        var id = node.getAttribute('id');\n \
        if (optimized) {\n \
            if (id)\n \
                return new UTILS.DOMNodePathStep(idSelector(id), true);\n \
            var nodeNameLower = node.nodeName.toLowerCase();\n \
            if (nodeNameLower === 'body' || nodeNameLower === 'head' || nodeNameLower === 'html')\n \
                return new UTILS.DOMNodePathStep(node.nodeName.toLowerCase(), true);\n \
         }\n \
        var nodeName = node.nodeName.toLowerCase();\n \
     \n \
        if (id)\n \
            return new UTILS.DOMNodePathStep(nodeName.toLowerCase() + idSelector(id), true);\n \
        var parent = node.parentNode;\n \
        if (!parent || parent.nodeType === Node.DOCUMENT_NODE)\n \
            return new UTILS.DOMNodePathStep(nodeName.toLowerCase(), true);\n \
    \n \
    \n \
        function prefixedElementClassNames(node)\n \
        {\n \
            var classAttribute = node.getAttribute('class');\n \
            if (!classAttribute)\n \
                return [];\n \
    \n \
            return classAttribute.split(/\\s+/g).filter(Boolean).map(function(name) {\n \
                return '$' + name;\n \
            });\n \
         }\n \
     \n \
    \n \
        function idSelector(id)\n \
        {\n \
            return '#' + escapeIdentifierIfNeeded(id);\n \
        }\n \
    \n \
        function escapeIdentifierIfNeeded(ident)\n \
        {\n \
            if (isCSSIdentifier(ident))\n \
                return ident;\n \
            var shouldEscapeFirst = /^(?:[0-9]|-[0-9-]?)/.test(ident);\n \
            var lastIndex = ident.length - 1;\n \
            return ident.replace(/./g, function(c, i) {\n \
                return ((shouldEscapeFirst && i === 0) || !isCSSIdentChar(c)) ? escapeAsciiChar(c, i === lastIndex) : c;\n \
            });\n \
        }\n \
    \n \
    \n \
        function escapeAsciiChar(c, isLast)\n \
        {\n \
            return '\\\\' + toHexByte(c) + (isLast ? '' : ' ');\n \
        }\n \
    \n \
    \n \
        function toHexByte(c)\n \
        {\n \
            var hexByte = c.charCodeAt(0).toString(16);\n \
            if (hexByte.length === 1)\n \
              hexByte = '0' + hexByte;\n \
            return hexByte;\n \
        }\n \
    \n \
        function isCSSIdentChar(c)\n \
        {\n \
            if (/[a-zA-Z0-9_-]/.test(c))\n \
                return true;\n \
            return c.charCodeAt(0) >= 0xA0;\n \
        }\n \
    \n \
    \n \
        function isCSSIdentifier(value)\n \
        {\n \
            return /^-?[a-zA-Z_][a-zA-Z0-9_-]*$/.test(value);\n \
        }\n \
    \n \
        var prefixedOwnClassNamesArray = prefixedElementClassNames(node);\n \
        var needsClassNames = false;\n \
        var needsNthChild = false;\n \
        var ownIndex = -1;\n \
        var siblings = parent.children;\n \
        for (var i = 0; (ownIndex === -1 || !needsNthChild) && i < siblings.length; ++i) {\n \
            var sibling = siblings[i];\n \
            if (sibling === node) {\n \
                ownIndex = i;\n \
                continue;\n \
            }\n \
            if (needsNthChild)\n \
                continue;\n \
            if (sibling.nodeName.toLowerCase() !== nodeName.toLowerCase())\n \
                continue;\n \
    \n \
            needsClassNames = true;\n \
            var ownClassNames = prefixedOwnClassNamesArray;\n \
            var ownClassNameCount = 0;\n \
            for (var cn_idx = 0; cn_idx < ownClassNames.length; cn_idx++)\n \
                ++ownClassNameCount;\n \
            if (ownClassNameCount === 0) {\n \
                needsNthChild = true;\n \
                continue;\n \
            }\n \
            var siblingClassNamesArray = prefixedElementClassNames(sibling);\n \
            for (var j = 0; j < siblingClassNamesArray.length; ++j) {\n \
                var siblingClass = siblingClassNamesArray[j];\n \
                var o_idx = ownClassNames.indexOf(siblingClass);\n \
                if (o_idx === -1)\n \
                    continue;\n \
                ownClassNames.splice(o_idx,1);\n \
                if (!--ownClassNameCount) {\n \
                    needsNthChild = true;\n \
                    break;\n \
                }\n \
            }\n \
        }\n \
     \n \
        var result = nodeName.toLowerCase();\n \
        if (isTargetNode && nodeName.toLowerCase() === 'input' && node.getAttribute('type') && !node.getAttribute('id') && !node.getAttribute('class'))\n \
            result += '[type=\\'' + node.getAttribute('type') + '\\']';\n \
        if (needsNthChild) {\n \
            result += ':nth-child(' + (ownIndex + 1) + ')';\n \
        } else if (needsClassNames) {\n \
            for (var idx = 0;idx < ownClassNames.length; idx++) {\n \
                result += '.' + escapeIdentifierIfNeeded(ownClassNames[idx].substr(1));\n \
            }\n \
        }\n \
    \n \
        return new UTILS.DOMNodePathStep(result, false);\n \
    };\n \
    \n \
    \n \
    UTILS.DOMNodePathStep = function(value, optimized)\n \
    {\n \
        this.value = value;\n \
        this.optimized = optimized || false;\n \
    };\n \
    \n \
    UTILS.DOMNodePathStep.prototype = {\n \
    \n \
        toString: function()\n \
        {\n \
            return this.value;\n \
        }\n \
    };";
}

@end









