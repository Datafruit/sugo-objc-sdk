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
#import "Sugo.h"
#import <objc/runtime.h>
#import "ExceptionUtils.h"


@interface MPObjectSerializer (WebViewSerializer)

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView;
- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView;

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
    @try {
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
                CGFloat xNum = (x-xMegin)/(xDistance+width)-(int)((x-xMegin)/(xDistance+width))>0?(int)(x-xMegin)/(xDistance+width)+1:(x-xMegin)/(xDistance+width);
                NSInteger cellIndex= (y-yMegin)/(yDistance+height)*itemNum + xNum;
                [dict[@"properties"] setValue:[NSString stringWithFormat:@"%d",cellIndex] forKey:@"cellIndex"];
            }
            [objectArray addObjectsFromArray:collectionViewCellArray];
        }
        

        return @{
                @"objects": objectArray,
                @"rootObject": [_objectIdentityProvider identifierForObject:rootObject],
                @"classAttr":[[Sugo sharedInstance] requireClassAttributeDict]
        };
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return @{
                 @"objects": @"",
                 @"rootObject": @"",
                 @"classAttr":@""
                 };
    }
}

#pragma mark Gets the frame value of the webview or wkwebview
-(NSDictionary *)requrieWidgetFrame:(NSMutableDictionary *)serializedObject{
    @try {
        NSDictionary *properties=serializedObject[@"properties"];
        NSDictionary *frame=properties[@"frame"];
        NSArray *values=frame[@"values"];
        NSDictionary *dict=values[0];
        NSDictionary *value=dict[@"value"];
        return value;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
}

//find collection的line distance，item distance，left megin，top megin。
//type:require X array or Y array;     0:X array ;   1:Y array;
-(NSDictionary *)findCollectionViewCellInterval:(NSMutableArray *)xArray withType:(NSInteger)type{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return @{@"distance":@(0),
                 @"megin":@(0),
                 @"itemNum":@(0)
                 };
    }

}

- (NSMutableArray *)visitObject:(NSObject *)object withContext:(MPObjectSerializerContext *)context withItemArray:(NSMutableArray *)itemArray
{
    @try {
        NSParameterAssert(object != nil);
        NSParameterAssert(context != nil);

    //    if ([object isKindOfClass:[UIView class]] && !((UIView *)object).translatesAutoresizingMaskIntoConstraints) {
    //        [((UIView *)object) setTranslatesAutoresizingMaskIntoConstraints:YES];
    //    }
        
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
        
        [self checkClassAttr:object];
        
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
        if ([object isKindOfClass:[UIWebView class]]
            && ((UIWebView *)object).window != nil) {
            [serializedObject setObject:[self getUIWebViewHTMLInfoFrom:(UIWebView *)object]
                                 forKey:@"htmlPage"];
        } else if ([object isKindOfClass:[WKWebView class]] && !((WKWebView *)object).loading) {
            [serializedObject setObject:[self getWKWebViewHTMLInfoFrom:(WKWebView *)object]
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

#pragma mark add cellIndex value To the uitableviewcell
-(NSMutableDictionary *)addTableViewCellIndexToSerializedObject:(NSMutableDictionary *)serializedObject{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return serializedObject;
    }
}

// according to the  tableviewcell to find tableview's MPClassDescription，the purpose is require tableviewcell's delegateclass
-(MPClassDescription *)classDescriptionForTableViewCellObject:(NSObject *)object{
    @try {
        NSParameterAssert(object != nil);
        MPClassDescription *parentDescription;
        Class viewClass=[[self requireParentObjectFromTableViewCellObject:object] class];
        parentDescription = [_configuration classWithName:NSStringFromClass(viewClass)];
        return parentDescription;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

-(NSObject *)requireParentObjectFromTableViewCellObject:(NSObject *)object{
    @try {
        UIView *view=(UIView *)object;
        while (![NSStringFromClass([view class]) isEqualToString:@"UITableView"]) {
            view=view.superview;
        }
        return (NSObject *)view;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return object;
    }
}

-(MPClassDescription *)classDescriptionForCollectionViewCellObject:(NSObject *)object{
    @try {
        NSParameterAssert(object != nil);
        MPClassDescription *parentDescription;
        Class viewClass=[[self requireParentObjectFromCollectionViewCellObject:object] class];
        parentDescription = [_configuration classWithName:NSStringFromClass(viewClass)];
        return parentDescription;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

-(NSObject *)requireParentObjectFromCollectionViewCellObject:(NSObject *)object{
    @try {
        UIView *view=(UIView *)object;
        while (![NSStringFromClass([view class]) isEqualToString:@"UICollectionView"]) {
            view=view.superview;
        }
        return (NSObject *)view;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return object;
    }
}


-(void)checkClassAttr:(NSObject *)object{
    @try {
        NSMutableDictionary *dict =  [[Sugo sharedInstance] requireClassAttributeDict];
        NSString *className =[self classHierarchyArrayForObject:object][0];
        NSString *value = dict[className];
        if (value != nil) {
            return;
        }
        unsigned int count = 0;
        Class c = [object class];
        NSMutableArray *valueArray = [[NSMutableArray alloc]init];
        while (c) {
            NSMutableDictionary *widgetAttr = [[Sugo sharedInstance]requireWidgetAttributeDict];
            NSString *widgetName =NSStringFromClass(c);
            NSMutableArray *widgetAttrValue = widgetAttr[widgetName];
            if (widgetAttrValue!=nil) {
                [valueArray addObjectsFromArray:widgetAttrValue];
                c = class_getSuperclass(c);
                continue;
            }
            NSMutableArray *currentValue = [[NSMutableArray alloc]init];
            Ivar *ivars = class_copyIvarList(c, &count);
            for (int i = 0; i<count; i++) {
                Ivar ivar = ivars[i];
                NSString *valueType = [NSString stringWithFormat:@"%s",ivar_getTypeEncoding(ivar)];
                if ([self isBaseType:valueType]){
                    [currentValue addObject:[NSString stringWithFormat:@"%s",ivar_getName(ivar)]];
                }
            }
            widgetAttrValue = [[NSMutableArray alloc]init];
            [widgetAttrValue addObjectsFromArray:currentValue];
            [valueArray addObjectsFromArray:currentValue];
            widgetAttr[widgetName]=widgetAttrValue;
            [[Sugo sharedInstance]buildWidgetAttributeDict:widgetAttr];
            free(ivars);
            c = class_getSuperclass(c);
        }
        [valueArray addObject:@"text"];
        value = [valueArray componentsJoinedByString:@","];
        dict[className] = value;
        [[Sugo sharedInstance] buildClassAttributeDict:dict];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}



-(BOOL)isBaseType:(NSString *)typeName{
    @try {
        NSArray *array = [[NSArray alloc]initWithObjects:@"int",@"double",@"float",@"char",@"long",@"short",@"signed",@"unsigned",@"short int",@"long int",@"unsigned int",@"unsigned short",@"unsigned long",@"long double",@"number",@"Boolean",@"BOOL",@"bool",@"NSString",@"NSDate",@"NSNumber",@"NSInteger",@"NSUInteger",@"enum",@"struct",@"B",@"Q",@"d",@"q",@"c",@"i",@"s",@"l",@"C",@"I",@"S",@"L",@"f",@"d",@"b",nil];
        BOOL isBaseType = false;
        typeName = [typeName stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        typeName = [typeName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        typeName = [typeName stringByReplacingOccurrencesOfString:@"@" withString:@""];
        for (NSString *item in array){
            if ([typeName isEqualToString:item]) {
                isBaseType = true;
                break;
            }
        }
        return isBaseType;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return NO;
    }
    
}

- (NSArray *)classHierarchyArrayForObject:(NSObject *)object
{
    @try {
        NSMutableArray *classHierarchy = [NSMutableArray array];

        Class aClass = [object class];
        while (aClass)
        {
            [classHierarchy addObject:NSStringFromClass(aClass)];
            aClass = [aClass superclass];
        }

        return [classHierarchy copy];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSArray alloc]init];
    }
}

- (NSArray *)allValuesForType:(NSString *)typeName
{
    @try {
        NSParameterAssert(typeName != nil);

        MPTypeDescription *typeDescription = [_configuration typeWithName:typeName];
        if ([typeDescription isKindOfClass:[MPEnumDescription class]]) {
            MPEnumDescription *enumDescription = (MPEnumDescription *)typeDescription;
            return [enumDescription allValues];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return @[];
}

- (NSArray *)parameterVariationsForPropertySelector:(MPPropertySelectorDescription *)selectorDescription
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSArray alloc]init];
    }
}

- (id)instanceVariableValueForObject:(id)object propertyDescription:(MPPropertyDescription *)propertyDescription
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

    return nil;
}

- (NSInvocation *)invocationForObject:(id)object withSelectorDescription:(MPPropertySelectorDescription *)selectorDescription
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

- (id)propertyValue:(id)propertyValue propertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

- (id)propertyValueForObject:(NSObject *)object withPropertyDescription:(MPPropertyDescription *)propertyDescription context:(MPObjectSerializerContext *)context
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return @{@"values":@""};
    }
}

- (BOOL)isNestedObjectType:(NSString *)typeName
{
    return [_configuration classWithName:typeName] != nil;
}

- (MPClassDescription *)classDescriptionForObject:(NSObject *)object
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

@end

@implementation MPObjectSerializer (WebViewSerializer)

- (NSDictionary *)getUIWebViewHTMLInfoFrom:(UIWebView *)webView
{
    @try {
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
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
}

- (NSDictionary *)getWKWebViewHTMLInfoFrom:(WKWebView *)webView
{
    @try {
        WebViewBindings *wvBindings = [WebViewBindings globalBindings];
        [webView evaluateJavaScript:[wvBindings jsSourceOfFileName:@"WebViewExecute.Report"] completionHandler:nil];

        return [[WebViewInfoStorage globalStorage] getHTMLInfo];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

@end









