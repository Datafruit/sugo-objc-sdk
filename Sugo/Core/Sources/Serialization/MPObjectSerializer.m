//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "UIView+MPHelpers.h"
#import "MPClassDescription.h"
#import "MPEnumDescription.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializer.h"
#import "MPObjectSerializerConfig.h"
#import "MPObjectSerializerContext.h"
#import "MPPropertyDescription.h"
#import "NSInvocation+MPHelpers.h"
#import "WebViewBindings+WebView.h"
#import "WebViewInfoStorage.h"


@interface MPObjectSerializer (WebViewSerializer)

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView;
- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView;
- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView withWebViewFrame:(NSDictionary *)webFrame;
- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView withWebViewFrame:(NSDictionary *)webFrame;

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
    NSMutableArray *collectionViewCellArray=[NSMutableArray new];
    while ([context hasUnvisitedObjects])
    {
        
        NSObject *object=[context dequeueUnvisitedObject];
        NSString *objectName=NSStringFromClass([object class]);
        //This change is to add a subscript to each cell to solve the problem of cell scrambling in the server path
        if([objectName isEqualToString:@"UICollectionViewCell"]){
            collectionViewCellArray=[self visitObject:object withContext:context withItemArray:collectionViewCellArray];
        }else{
            [self visitObject:object withContext:context withItemArray:nil];
        }
    }
    
    NSMutableArray *objectArray=[[context allSerializedObjects] mutableCopy];
    
    
    //if have collectionviewcell，set cellindex value to the collectionviewcell。
    if (collectionViewCellArray.count>0) {
        NSDictionary *xDict=[self findCollectionViewCellInterval:collectionViewCellArray withType:0];
        NSDictionary *yDict=[self findCollectionViewCellInterval:collectionViewCellArray withType:1];
        CGFloat xDistance=[xDict[@"distance"] floatValue];
        CGFloat xMegin=[xDict[@"megin"] floatValue];
        CGFloat itemNum=[xDict[@"itemNum"] floatValue];
        CGFloat yDistance=[yDict[@"distance"] floatValue];
        CGFloat yMegin=[yDict[@"megin"] floatValue];
        for (NSMutableDictionary *dict in collectionViewCellArray) {
            NSDictionary *value=[self requrieWidgetFrame:dict];
            CGFloat y=[value[@"Y"] floatValue];
            CGFloat x=[value[@"X"] floatValue];
            CGFloat width=[value[@"Width"] floatValue];
            CGFloat height=[value[@"Height"] floatValue];
            NSInteger cellIndex= (y-yMegin)/(yDistance+height)*itemNum + (x-xMegin)/(xDistance+width);
            [dict[@"properties"] setValue:[NSString stringWithFormat:@"%d",cellIndex] forKey:@"cellIndex"];
        }
        [objectArray addObjectsFromArray:collectionViewCellArray];
    }
    
    return @{
            @"objects": objectArray,
            @"rootObject": [_objectIdentityProvider identifierForObject:rootObject]
    };
}




//find collection的line distance，item distance，left megin，top megin。
//type:require X array or Y array;     0:X array ;   1:Y array;
-(NSDictionary *)findCollectionViewCellInterval:(NSMutableArray *)xArray withType:(NSInteger)type{
    NSDictionary *value=[self requrieWidgetFrame:xArray[0]];
    CGFloat size;
    if (type==0) {
        size=[((NSString *)value[@"Width"]) floatValue];
    }else{
        size=[((NSString *)value[@"Height"]) floatValue];
    }
    
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    for (int i=0; i<xArray.count; i++) {
        NSDictionary *value=[self requrieWidgetFrame:xArray[i]];
        CGFloat num;
        if (type==0) {
            num=[((NSString *)value[@"X"]) floatValue];
        }else{
            num=[((NSString *)value[@"Y"]) floatValue];
        }
        [arr addObject:@(num)];
    }
    
    //Delete the same element，and sort .
    NSArray *newArray=[[[NSSet setWithArray:arr] allObjects] sortedArrayUsingSelector:@selector(compare:)];
    float distance=0;
    float megin=0;
    CGFloat itemNum=0;

    if (newArray.count==1) {//special case
        megin=[newArray[0] floatValue];
    }else if(newArray.count>1){
        distance =[newArray[1] floatValue]-[newArray[0] floatValue]-size;
        NSInteger tmp= [newArray[0] floatValue]/(distance+size);
        megin=[newArray[0] floatValue]- tmp*(distance+size) ;
    }
    
    if (type==0) {//when is x array,require per line cell num;
        itemNum=([newArray[newArray.count-1] floatValue] - [newArray[0] floatValue])/(distance+size)+1;
    }
    NSDictionary * result = @{@"distance":@(distance),
                               @"megin":@(megin),
                              @"itemNum":@(itemNum)
                              };
    return result;
}

- (NSMutableArray *)visitObject:(NSObject *)object withContext:(MPObjectSerializerContext *)context withItemArray:(NSMutableArray *)itemArray
{
    NSParameterAssert(object != nil);
    NSParameterAssert(context != nil);
    
    
    
//    if ([object isKindOfClass:[UIView class]] && !((UIView *)object).translatesAutoresizingMaskIntoConstraints) {
//        [((UIView *)object) setTranslatesAutoresizingMaskIntoConstraints:YES];
//    }
    
    [context addVisitedObject:object];
    NSMutableDictionary *propertyValues = [NSMutableDictionary dictionary];
    MPClassDescription *classDescription = [self classDescriptionForObject:object];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        if (classDescription) {
            for (MPPropertyDescription *propertyDescription in [classDescription propertyDescriptions]) {
                if ([propertyDescription shouldReadPropertyValueForObject:object]) {
                    id propertyValue = [self propertyValueForObject:object withPropertyDescription:propertyDescription context:context];
                    propertyValues[propertyDescription.name] = propertyValue ?: [NSNull null];
                }
            }
        }
    });
    NSMutableArray *delegateMethods = [NSMutableArray array];
    id delegate;
    SEL delegateSelector = @selector(delegate);
    NSObject *tmpObject=object;
    
    //Special circumstances:get the delegateclass and delegateMethods of subView through parentView;so transform parentView;
    if ([NSStringFromClass([object class]) isEqualToString:@"UITableViewCell"]) {
        classDescription = [self classDescriptionForTableViewCellObject:object];
        tmpObject=[self requireParentObjectFromTableViewCellObject:object];
    }else if([NSStringFromClass([object class]) isEqualToString:@"UICollectionViewCell"]){
        classDescription = [self classDescriptionForCollectionViewCellObject:object];
        tmpObject=[self requireParentObjectFromCollectionViewCellObject:object];
    }
    
    
    if ([classDescription delegateInfos].count > 0 && [tmpObject respondsToSelector:delegateSelector]) {
        delegate = ((id (*)(id, SEL))[tmpObject methodForSelector:delegateSelector])(tmpObject, delegateSelector);
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
   

    
    if ([NSStringFromClass([object class]) isEqualToString:@"UIWebView"] && ((UIWebView *)object).window != nil) {
        NSDictionary *webFrame=[self requrieWidgetFrame:serializedObject];
        [serializedObject setObject:[self getUIWebViewHTMLInfoFrom:(UIWebView *)object withWebViewFrame:webFrame]
                             forKey:@"htmlPage"];
    } else if ([NSStringFromClass([object class]) isEqualToString:@"WKWebView"] && !((WKWebView *)object).loading) {
        NSDictionary *webFrame=[self requrieWidgetFrame:serializedObject];
        [serializedObject setObject:[self getWKWebViewHTMLInfoFrom:(WKWebView *)object withWebViewFrame:webFrame]
                             forKey:@"htmlPage"];
    }
    
    
    
    if ([NSStringFromClass([object class]) isEqualToString:@"UITableViewCell"]) {
        [context addSerializedObject:[self addTableViewCellIndexToSerializedObject:serializedObject]];
        return nil;
    }else if([NSStringFromClass([object class]) isEqualToString:@"UICollectionViewCell"]){
        [itemArray addObject:serializedObject];
        return itemArray;
    }else{
        [context addSerializedObject:serializedObject];
        return  nil;
    }
}

#pragma mark add cellIndex value To the uitableviewcell
-(NSMutableDictionary *)addTableViewCellIndexToSerializedObject:(NSMutableDictionary *)serializedObject{
    NSDictionary *properties=serializedObject[@"properties"];
    NSDictionary *frame=properties[@"frame"];
    NSArray *values=frame[@"values"];
    NSDictionary *dict=values[0];
    NSDictionary *value=dict[@"value"];
    CGFloat height=[((NSString *)value[@"Height"]) floatValue];
    
    NSDictionary *center=properties[@"center"];
    NSArray *valuesCenter=center[@"values"];
    NSDictionary *dictCenter=valuesCenter[0];
    NSDictionary *valueCenter=dictCenter[@"value"];
    CGFloat y =[((NSString *)valueCenter[@"Y"]) floatValue];
    int i=(y-height/2)/height;
    [serializedObject[@"properties"] setValue:[NSString stringWithFormat:@"%d",i] forKey:@"cellIndex"];
    return serializedObject;
}


#pragma mark Gets the frame value of the webview or wkwebview
-(NSDictionary *)requrieWidgetFrame:(NSMutableDictionary *)serializedObject{
    NSDictionary *properties=serializedObject[@"properties"];
    NSDictionary *frame=properties[@"frame"];
    NSArray *values=frame[@"values"];
    NSDictionary *dict=values[0];
    NSDictionary *value=dict[@"value"];
    return value;
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

- (id)propertyValue:(id)propertyValue propertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context isViewControllers:(BOOL)isTrue
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
            if (isTrue) {   // this block can delete all navigationcoller subviews, and only save the latest subview to the context.unvisitedObjects
                NSMutableArray *array=(NSMutableArray *)propertyValue;
                for (int i=0; i<array.count; i++) {
                    if (i<array.count-1) {
                        [context addVisitedObject:array[i]];
                    }else{
                        if ([context isVisitedObject:array[i]] == NO) {
                            [context enqueueUnvisitedObject:array[i]];
                        }
                    }
                }
            }else{
                for (id value in propertyValue) {
                    if ([context isVisitedObject:value] == NO) {
                        [context enqueueUnvisitedObject:value];
                    }
                    
                    [arrayOfIdentifiers addObject:[_objectIdentityProvider identifierForObject:value]];
                }
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
        BOOL isTrue=false;
        if([NSStringFromClass([object class]) isEqualToString:@"UINavigationController"]&&[propertyDescription.name isEqualToString:@"viewControllers"]) {
            isTrue=YES;
        }
        id value = [self propertyValue:valueForKey
                   propertyDescription:propertyDescription
                               context:context
                     isViewControllers:isTrue];
        
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

// according to the  tableviewcell to find tableview's MPClassDescription，the purpose is require tableviewcell's delegateclass
-(MPClassDescription *)classDescriptionForTableViewCellObject:(NSObject *)object{
    NSParameterAssert(object != nil);
    MPClassDescription *parentDescription;
    Class viewClass=[[self requireParentObjectFromTableViewCellObject:object] class];
    parentDescription = [_configuration classWithName:NSStringFromClass(viewClass)];
    return parentDescription;
}

-(NSObject *)requireParentObjectFromTableViewCellObject:(NSObject *)object{
    UIView *view=(UIView *)object;
    while (![NSStringFromClass([view class]) isEqualToString:@"UITableView"]) {
        view=view.superview;
    }
    return (NSObject *)view;
}

-(MPClassDescription *)classDescriptionForCollectionViewCellObject:(NSObject *)object{
    NSParameterAssert(object != nil);
    MPClassDescription *parentDescription;
    Class viewClass=[[self requireParentObjectFromCollectionViewCellObject:object] class];
    parentDescription = [_configuration classWithName:NSStringFromClass(viewClass)];
    return parentDescription;
}

-(NSObject *)requireParentObjectFromCollectionViewCellObject:(NSObject *)object{
    UIView *view=(UIView *)object;
    while (![NSStringFromClass([view class]) isEqualToString:@"UICollectionView"]) {
        view=view.superview;
    }
    return (NSObject *)view;
}



@end

@implementation MPObjectSerializer (WebViewSerializer)

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView
{
    WebViewBindings *wvBindings = [WebViewBindings globalBindings];
    NSString *eventString = [webView stringByEvaluatingJavaScriptFromString:[wvBindings jsSourceOfFileName:@"WebViewExecute.Report"]];
    NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *event = [NSJSONSerialization JSONObjectWithData:eventData
                                                          options:NSJSONReadingMutableContainers
                                                            error:nil];
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    if (event[@"title"]
        && event[@"path"]
        && event[@"clientWidth"]
        && event[@"clientHeight"]
        && event[@"viewportContent"]
        && event[@"nodes"]) {
        [storage setHTMLInfoWithTitle:(NSString *)event[@"title"]
                                 path:(NSString *)event[@"path"]
                                width:(NSString *)event[@"clientWidth"]
                               height:(NSString *)event[@"clientHeight"]
                      viewportContent:(NSString *)event[@"viewportContent"]
                                nodes:(NSString *)event[@"nodes"]];
    }
    eventString = nil;
    eventData = nil;
    event = nil;
    return [storage getHTMLInfo];
}

- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView
{
    
    WebViewBindings *wvBindings = [WebViewBindings globalBindings];
    [webView evaluateJavaScript:[wvBindings jsSourceOfFileName:@"WebViewExecute.Report"] completionHandler:nil];

    return [[WebViewInfoStorage globalStorage] getHTMLInfo];
}


#pragma mark Gets the frame value of the wkwebview and adds the absolute displacement field to the htmlpage field
- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView withWebViewFrame:(NSDictionary *)webFrame
{
    __block NSMutableDictionary *newdict;
    NSInteger hash=webView.hash;
    WebViewBindings *wvBindings = [WebViewBindings globalBindings];
    [[WebViewInfoStorage globalStorage]setupWebViewLoadStatus:0 hash:hash];
    dispatch_async(dispatch_get_main_queue(), ^{
        [webView evaluateJavaScript:[wvBindings jsSourceOfFileName:@"WebViewExecute.Report"] completionHandler:^(id object, NSError *error){
                [[WebViewInfoStorage globalStorage]setupWebViewLoadStatus:1 hash:hash];
        }];
    });
    while (![[WebViewInfoStorage globalStorage] requireWebViewLoadStatus:hash]) {
        [NSThread sleepForTimeInterval:0.1];
    }
    NSDictionary *dict=[[WebViewInfoStorage globalStorage] getHTMLInfoWithHash:hash];
    newdict = [NSMutableDictionary dictionaryWithDictionary:dict];
    float clientHeight=[newdict[@"clientHeight"] floatValue];
    float webHeight=[webFrame[@"Height"] floatValue];
    float distance= clientHeight==0?0:webHeight-clientHeight;
    [newdict setValue:[NSString stringWithFormat:@"%lf",distance] forKey:@"distance"];
    return newdict;
}



#pragma mark Get the frame value of the webview and add the absolute displacement field to the htmlpage field
- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView withWebViewFrame:(NSDictionary *)webFrame
{
    WebViewInfoStorage *storage = [WebViewInfoStorage globalStorage];
    dispatch_sync(dispatch_get_main_queue(), ^{
        WebViewBindings *wvBindings = [WebViewBindings globalBindings];
        NSString *eventString = @"no message";
        eventString = [webView stringByEvaluatingJavaScriptFromString:[wvBindings jsSourceOfFileName:@"WebViewExecute.Report"]];
        NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDic = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:nil];
        float clientHeight=[tempDic[@"clientHeight"] floatValue];
        float webHeight=[webFrame[@"Height"] floatValue];
        float distance= clientHeight==0?0:webHeight-clientHeight;
        
        NSDictionary *event = [NSJSONSerialization JSONObjectWithData:eventData
                                                              options:NSJSONReadingMutableContainers
                                                                error:nil];
        if (event[@"title"]
            && event[@"path"]
            && event[@"clientWidth"]
            && event[@"clientHeight"]
            && event[@"viewportContent"]
            && event[@"nodes"]) {
            [storage setHTMLInfoWithTitle:(NSString *)event[@"title"]
                                     path:(NSString *)event[@"path"]
                                    width:(NSString *)event[@"clientWidth"]
                                   height:(NSString *)event[@"clientHeight"]
                          viewportContent:(NSString *)event[@"viewportContent"]
                                    nodes:(NSString *)event[@"nodes"]
                                 distance:[NSString stringWithFormat:@"%lf",distance]
             ];
        }
        eventString = nil;
        eventData = nil;
        event = nil;
    });
    return [storage getHTMLInfo];
}

@end









