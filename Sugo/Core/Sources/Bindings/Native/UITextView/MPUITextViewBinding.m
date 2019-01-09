//
//  MPUITextViewBinding.m
//  Sugo
//
//  Created by Zack on 24/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "MPUITextViewBinding.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "MPSwizzler.h"
#import "SugoPrivate.h"
#import "UIViewController+SugoHelpers.h"
#import "MPLogger.h"

@implementation MPUITextViewBinding

+ (NSString *)typeName
{
    return @"ui_text_view";
}

+ (MPEventBinding *)bindingWithJSONObject:(NSDictionary *)object
{
    NSString *path = object[@"path"];
    if (![path isKindOfClass:[NSString class]] || path.length < 1) {
        MPLogDebug(@"must supply a view path to bind by");
        return nil;
    }
    
    NSString *eventID = object[@"event_id"];
    if (![eventID isKindOfClass:[NSString class]] || eventID.length < 1 ) {
        MPLogDebug(@"binding requires an event id");
        return nil;
    }
    
    NSString *eventName = object[@"event_name"];
    if (![eventName isKindOfClass:[NSString class]] || eventName.length < 1 ) {
        MPLogDebug(@"binding requires an event name");
        return nil;
    }
    
    Class delegate = NSClassFromString(object[@"table_delegate"]);
    if (!delegate || ![delegate instancesRespondToSelector:@selector(textViewDidBeginEditing:)]) {
        MPLogDebug(@"binding requires a delegate class");
        return nil;
    }
    
    NSDictionary *attributesPaths = object[@"attributes"];
    Attributes *attributes = [[Attributes alloc] initWithAttributes:attributesPaths];
    
    return [[MPUITextViewBinding alloc] initWithEventID:(NSString *)eventID
                                              eventName:eventName
                                                 onPath:path
                                           withDelegate:delegate
                                             attributes:attributes];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
+ (MPEventBinding *)bindngWithJSONObject:(NSDictionary *)object
{
    return [self bindingWithJSONObject:object];
}
#pragma clang diagnostic pop

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                     attributes:(Attributes *)attributes
{
    return [self initWithEventID:eventID
                       eventName:eventName
                          onPath:path
                    withDelegate:nil
                      attributes:attributes];
}

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                   withDelegate:(Class)delegateClass
                     attributes:(Attributes *)attributes
{
    if (self = [super initWithEventID:eventID
                            eventName:eventName
                               onPath:path
                       withAttributes:attributes]) {
        [self setSwizzleClass:delegateClass];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"UITextView Event Tracking: '%@' for '%@'", [self eventName], [self path]];
}

#pragma mark -- Executing Actions

- (void)execute
{
    if (!self.running && self.swizzleClass != nil) {
        void (^block)(id, SEL, id) = ^(id view, SEL command, UITextView *textView) {
            NSObject *root = [UIApplication sharedApplication].keyWindow;
            // select targets based off path
            if (textView && [self.path isLeafSelected:textView fromRoot:root]) {
                NSString *text = textView.text?textView.text:@"";
                NSMutableDictionary *p = [NSMutableDictionary dictionary];
                if (self.attributes) {
                    [p addEntriesFromDictionary:[self.attributes parse]];
                }
                if ([Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]
                    && [Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]) {
                    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
                    NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
                    p[keys[@"EventLabel"]] = text;
                    p[keys[@"EventType"]] = values[@"focus"];
//                    p[keys[@"PagePath"]] = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
//                    if ([SugoPageInfos global].infos.count > 0) {
//                        for (NSDictionary *info in [SugoPageInfos global].infos) {
//                            if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
//                                p[keys[@"PageName"]] = info[@"page_name"];
//                                if (info[@"page_category"]) {
//                                    p[keys[@"PageCategory"]] = info[@"page_category"];
//                                }
//                            }
//                        }
//                    }
                }
                NSString *classAttr = [self classAttr];
                if (classAttr !=nil&&classAttr.length>0) {
                    NSArray *attrArray = [classAttr componentsSeparatedByString:@","];
                    for (NSString *item in attrArray) {
                        id value = [textView valueForKey:item];
                        p[item] = value;
                    }
                }
                [[self class] track:[self eventID]
                          eventName:[self eventName]
                         properties:p];
            }
        };
        
        [MPSwizzler swizzleSelector:@selector(textViewDidBeginEditing:)
                            onClass:self.swizzleClass
                          withBlock:block
                              named:self.name];
        self.running = true;
    }
}

- (void)stop
{
    if (self.running && self.swizzleClass != nil) {
        [MPSwizzler unswizzleSelector:@selector(textViewDidBeginEditing:)
                              onClass:self.swizzleClass
                                named:self.name];
        self.running = false;
    }
}

@end










