//
//  MPUITableViewBinding.m
//  HelloSugo
//
//  Created by Amanda Canyon on 8/5/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "MPSwizzler.h"
#import "MPUITableViewBinding.h"
#import "SugoPrivate.h"
#import "MPLogger.h"

@implementation MPUITableViewBinding

+ (NSString *)typeName
{
    return @"ui_table_view";
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

    Class tableDelegate = NSClassFromString(object[@"table_delegate"]);
    if (!tableDelegate) {
        MPLogDebug(@"binding requires a table_delegate class");
        return nil;
    }

    NSDictionary *attributesPaths = object[@"attributes"];
    Attributes *attributes = [[Attributes alloc] initWithAttributes:attributesPaths];
    
    return [[MPUITableViewBinding alloc] initWithEventID:(NSString *)eventID
                                               eventName:eventName
                                                  onPath:path
                                            withDelegate:tableDelegate
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
    return [NSString stringWithFormat:@"UITableView Event Tracking: '%@' for '%@'", [self eventName], [self path]];
}


#pragma mark -- Executing Actions

- (void)execute
{
    if (!self.running && self.swizzleClass != nil) {
        void (^block)(id, SEL, id, id) = ^(id view, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
            NSObject *root = [UIApplication sharedApplication].keyWindow.rootViewController;
            // select targets based off path
            if (tableView && [self.path isLeafSelected:tableView fromRoot:root]) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                NSString *label = (cell && cell.textLabel && cell.textLabel.text) ? cell.textLabel.text : @"";
                
                NSMutableDictionary *p = [[NSMutableDictionary alloc]
                                          initWithDictionary:@{
                                                               @"Cell Index": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.row],
                                                               @"Cell Section": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.section],
                                                               @"Cell Label": label
                                                               }];
                if (self.attributes) {
                    [p addEntriesFromDictionary:[self.attributes parse]];
                }
                if ([Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]) {
                    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
                    p[keys[@"EventType"]] = @"click";
                }

                [[self class] track:[self eventID]
                          eventName:[self eventName]
                         properties:p];
            }
        };

        [MPSwizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:)
                            onClass:self.swizzleClass
                          withBlock:block
                              named:self.name];
        self.running = true;
    }
}

- (void)stop
{
    if (self.running && self.swizzleClass != nil) {
        [MPSwizzler unswizzleSelector:@selector(tableView:didSelectRowAtIndexPath:)
                              onClass:self.swizzleClass
                                named:self.name];
        self.running = false;
    }
}

#pragma mark -- Helper Methods

- (UITableView *)parentTableView:(UIView *)cell {
    // iterate up the view hierarchy to find the table containing this cell/view
    UIView *aView = cell.superview;
    while (aView != nil) {
        if ([aView isKindOfClass:[UITableView class]]) {
            return (UITableView *)aView;
        }
        aView = aView.superview;
    }
    return nil; // this view is not within a tableView
}

@end
