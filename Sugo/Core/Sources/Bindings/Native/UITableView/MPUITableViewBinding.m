//
//  MPUITableViewBinding.m
//  Sugo
//
//  Created by Amanda Canyon on 8/5/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "MPSwizzler.h"
#import "MPUITableViewBinding.h"
#import "SugoPrivate.h"
#import "UIViewController+SugoHelpers.h"
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

    Class delegate = NSClassFromString(object[@"table_delegate"]);
    if (!delegate || ![delegate instancesRespondToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        MPLogDebug(@"binding requires a delegate class");
        return nil;
    }

    NSDictionary *attributesPaths = object[@"attributes"];
    Attributes *attributes = [[Attributes alloc] initWithAttributes:attributesPaths];
    
    return [[MPUITableViewBinding alloc] initWithEventID:(NSString *)eventID
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
    return [NSString stringWithFormat:@"UITableView Event Tracking: '%@' for '%@'", [self eventName], [self path]];
}


#pragma mark -- Executing Actions

- (void)execute
{
    if (!self.running && self.swizzleClass != nil) {
        void (^block)(id, SEL, id, id) = ^(id view, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
            NSObject *root = [UIApplication sharedApplication].keyWindow;
            // select targets based off path
            if (tableView && [self.path isLeafSelected:tableView fromRoot:root]) {
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                NSString *textLabel = (cell && cell.textLabel && cell.textLabel.text) ? cell.textLabel.text : @"";
                NSString *detailTextLabel = (cell && cell.detailTextLabel && cell.detailTextLabel.text) ? cell.detailTextLabel.text : @"";
                
                NSMutableDictionary *p = [[NSMutableDictionary alloc]
                                          initWithDictionary:@{
                                                               @"cell_index": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.row],
                                                               @"cell_section": [NSString stringWithFormat: @"%ld", (unsigned long)indexPath.section],
                                                               @"cell_label": textLabel,
                                                               @"cell_detail_label": detailTextLabel
                                                               }];
                if (self.attributes) {
                    [p addEntriesFromDictionary:[self.attributes parse]];
                }
                if ([Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]
                    && [Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]) {
                    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
                    NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
                    NSMutableString *contentInfo = [[self contentInfoOfView:cell.contentView] mutableCopy];
                    NSString *eventLabel = [NSString string];
                    if (contentInfo.length > 0) {
                        eventLabel = [contentInfo substringToIndex:(contentInfo.length - 1)];
                    }
                    p[keys[@"EventLabel"]] = eventLabel;
                    p[keys[@"EventType"]] = values[@"click"];
                    p[keys[@"PagePath"]] = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
                    if ([SugoPageInfos global].infos.count > 0) {
                        for (NSDictionary *info in [SugoPageInfos global].infos) {
                            if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
                                p[keys[@"PageName"]] = info[@"page_name"];
                                if (info[@"page_category"]) {
                                    p[keys[@"PageCategory"]] = info[@"page_category"];
                                }
                            }
                        }
                    }
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

- (NSString *)contentInfoOfView:(UIView *)view
{
    NSMutableString *infos = [NSMutableString string];
    for (UIView *subview in view.subviews) {
        NSString *label;
        if ([subview isKindOfClass:[UISearchBar class]] && ((UISearchBar *)subview).text) {
            label = ((UISearchBar *)subview).text;
        } else if ([subview isKindOfClass:[UIButton class]] && ((UIButton *)subview).titleLabel.text) {
            label = ((UIButton *)subview).titleLabel.text;
        } else if ([subview isKindOfClass:[UIDatePicker class]]) {
            label = [NSString stringWithFormat:@"%@", ((UIDatePicker *)subview).date];
        } else if ([subview isKindOfClass:[UISegmentedControl class]]) {
            label = [NSString stringWithFormat:@"%ld", (long)((UISegmentedControl *)subview).selectedSegmentIndex];
        } else if ([subview isKindOfClass:[UISlider class]]) {
            label = [NSString stringWithFormat:@"%f", ((UISlider *)subview).value];
        } else if ([subview isKindOfClass:[UISwitch class]]) {
            label = [NSString stringWithFormat:@"%i", ((UISwitch *)subview).isOn];
        } else if ([subview isKindOfClass:[UITextField class]]) {
            label = [NSString stringWithFormat:@"%@", ((UITextField *)subview).text];
        } else if ([subview isKindOfClass:[UITextView class]]) {
            label = [NSString stringWithFormat:@"%@", ((UITextView *)subview).text];
        } else if ([subview isKindOfClass:[UILabel class]] && ((UILabel *)subview).text) {
            label = [NSString stringWithFormat:@"%@", ((UILabel *)subview).text];
        }
        if (label && label.length > 0) {
            [infos appendString:label];
            [infos appendString:@","];
        }
        [infos appendString:[self contentInfoOfView:subview]];
    }
    return infos;
}

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
