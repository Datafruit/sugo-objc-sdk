//
//  MPUIViewBinding.m
//  HelloSugo
//
//  Created by Amanda Canyon on 8/4/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPSwizzler.h"
#import "MPUIViewBinding.h"
#import "Attributes.h"
#import "SugoPrivate.h"
#import "UIViewController+SugoHelpers.h"
#import "MPLogger.h"

@interface MPUIViewBinding()

/*
 This table contains all the UIControls we are currently bound to
 */
@property (nonatomic, copy) NSHashTable *appliedTo;
/*
 A table of all objects that matched the full path including
 predicates the last time they dispatched a UIControlEventTouchDown
 */
@property (nonatomic, copy) NSHashTable *verified;

- (void)stopOnView:(UIView *)view;

@end

@implementation MPUIViewBinding

+ (NSString *)typeName
{
    return @"ui_view";
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
    
    NSDictionary *attributesPaths = [NSDictionary dictionaryWithDictionary:object[@"attributes"]];
    Attributes *attributes = [[Attributes alloc] initWithAttributes:attributesPaths];

    if (!([object[@"control_event"] isKindOfClass:[NSNull class]])
        && ([object[@"control_event"] unsignedIntegerValue] & UIControlEventAllEvents)) {
        UIControlEvents verifyEvent = [object[@"verify_event"] unsignedIntegerValue];
        return [[MPUIViewBinding alloc] initWithEventID:eventID
                                              eventName:eventName
                                                 onPath:path
                                       withControlEvent:[object[@"control_event"] unsignedIntegerValue]
                                         andVerifyEvent:verifyEvent
                                             attributes:attributes];
    }
    
    return [[MPUIViewBinding alloc] initWithEventID:eventID
                                          eventName:eventName
                                             onPath:path
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
               withControlEvent:(UIControlEvents)controlEvent
                 andVerifyEvent:(UIControlEvents)verifyEvent
                     attributes:(Attributes *)attributes
{
    if (self = [super initWithEventID:eventID eventName:eventName onPath:path withAttributes:attributes]) {
        [self setSwizzleClass:[UIView class]];
        _controlEvent = controlEvent;
        _verifyEvent = _controlEvent;
        [self resetAppliedTo];
    }
    return self;
}

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                     attributes:(Attributes *)attributes
{
    if (self = [super initWithEventID:eventID eventName:eventName onPath:path withAttributes:attributes]) {
        [self setSwizzleClass:[UIView class]];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Event Binding: '%@' for '%@'", [self eventName], [self path]];
}

- (void)resetAppliedTo
{
    self.verified = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
    self.appliedTo = [NSHashTable hashTableWithOptions:(NSHashTableWeakMemory|NSHashTableObjectPointerPersonality)];
}

#pragma mark -- Executing Actions

- (void)execute
{
    if (!self.appliedTo) {
        [self resetAppliedTo];
    }
    
    if (!self.running) {
        void (^executeBlock)(id, SEL) = ^(id view, SEL command) {
            NSArray *objects;
            NSObject *root = [[UIApplication sharedApplication] keyWindow];
            if (view && [self.appliedTo containsObject:view]) {
                if (![self.path fuzzyIsLeafSelected:view fromRoot:root]) {
                    if ([Sugo sharedInstance].heatMap.mode) {
                        [[Sugo sharedInstance].heatMap wipeObjectOfPath:self.path.string];
                    }
                    [self stopOnView:view];
                    [self.appliedTo removeObject:view];
                }
            } else {
                // select targets based off path
                if (view) {
                    if ([self.path fuzzyIsLeafSelected:view fromRoot:root]) {
                        objects = @[view];
                    } else {
                        objects = @[];
                    }
                } else {
                    objects = [self.path selectFromRoot:root];
                }

                for (UIView *view in objects) {
                    if ([view isKindOfClass:[UIControl class]]) {
                        if (self.verifyEvent != 0 && self.verifyEvent != self.controlEvent) {
                            [(UIControl *)view addTarget:self
                                                  action:@selector(preVerify:forEvent:)
                                        forControlEvents:self.verifyEvent];
                        }

                        [(UIControl *)view addTarget:self
                                              action:@selector(execute:forEvent:)
                                    forControlEvents:self.controlEvent];
                    } else if (view.isUserInteractionEnabled && [view.gestureRecognizers count] > 0) {
                        for (UIGestureRecognizer *gestureRecognizer in view.gestureRecognizers) {
                            if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || !gestureRecognizer.enabled) {
                                continue;
                            }
                            [gestureRecognizer addTarget:self action:@selector(handleGesture:)];
                            break;
                        }
                    } else if (view.isUserInteractionEnabled && [NSStringFromClass([view class]) hasPrefix:@"RCT"]) {
                        UIGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
                        [view addGestureRecognizer:gestureRecognizer];
                    }
                    [self.appliedTo addObject:view];
                }
                if ([Sugo sharedInstance].heatMap.mode) {
                    [[Sugo sharedInstance].heatMap renderObjectOfPath:self.path.string fromRoot:root];
                }
            }
        };

        executeBlock(nil, _cmd);

        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:self.swizzleClass
                          withBlock:executeBlock
                              named:self.name];
        [MPSwizzler swizzleSelector:NSSelectorFromString(@"didMoveToSuperview")
                            onClass:self.swizzleClass
                          withBlock:executeBlock
                              named:self.name];
        self.running = true;
    }
}


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

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer {
    
    BOOL shouldTrack;
    UIView *view = gestureRecognizer.view;
    shouldTrack = [self verifyControlMatchesPath:view];
    if (shouldTrack) {
        NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
        if (self.attributes) {
            [p addEntriesFromDictionary:[self.attributes parse]];
        }
        if ([Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]
            && [Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]) {
            NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
            NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
            NSMutableString *contentInfo = [[self contentInfoOfView:view] mutableCopy];
            NSString *eventLabel = [NSString string];
            if (contentInfo.length > 0) {
                eventLabel = [contentInfo substringToIndex:(contentInfo.length - 1)];
            }
            p[keys[@"EventLabel"]] = eventLabel;
            p[keys[@"EventType"]] = values[@"click"];
//            p[keys[@"PagePath"]] = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
//            if ([SugoPageInfos global].infos.count > 0) {
//                for (NSDictionary *info in [SugoPageInfos global].infos) {
//                    if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
//                        p[keys[@"PageName"]] = info[@"page_name"];
//                        if (info[@"page_category"]) {
//                            p[keys[@"PageCategory"]] = info[@"page_category"];
//                        }
//                    }
//                }
//            }
        }
        [[self class] track:[self eventID] eventName:[self eventName] properties:p];
    }
}

- (void)stop
{
    if (self.running) {
        // remove what has been swizzled
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToWindow")
                            onClass:self.swizzleClass
                              named:self.name];
        [MPSwizzler unswizzleSelector:NSSelectorFromString(@"didMoveToSuperview")
                            onClass:self.swizzleClass
                              named:self.name];

        // remove target-action pairs
        for (UIView *view in self.appliedTo.allObjects) {
            if (view && [view isKindOfClass:[UIControl class]]) {
                [self stopOnView:view];
            }
        }
        [self resetAppliedTo];
        self.running = false;
    }
}

- (void)stopOnView:(UIView *)view
{
    if (view && [view isKindOfClass:[UIControl class]]) {
    
        if (self.verifyEvent != 0 && self.verifyEvent != self.controlEvent) {
            [(UIControl *)view removeTarget:self
                                     action:@selector(preVerify:forEvent:)
                           forControlEvents:self.verifyEvent];
        }
        [(UIControl *)view removeTarget:self
                                 action:@selector(execute:forEvent:)
                       forControlEvents:self.controlEvent];
    } else if (((UIView *)view).isUserInteractionEnabled && [((UIView *)view).gestureRecognizers count] > 0) {
        for (UIGestureRecognizer *gestureRecognizer in ((UIView *)view).gestureRecognizers) {
            if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || !gestureRecognizer.enabled) {
                continue;
            }
            [gestureRecognizer removeTarget:self action:@selector(handleGesture:)];
            break;
        }
    }
}

#pragma mark -- To execute for Target-Action event firing

- (BOOL)verifyControlMatchesPath:(id)control
{
    NSObject *root = [[UIApplication sharedApplication] keyWindow];
    return [self.path isLeafSelected:control fromRoot:root];
}

- (void)preVerify:(id)sender forEvent:(UIEvent *)event
{
    if ([self verifyControlMatchesPath:sender]) {
        [self.verified addObject:sender];
    } else {
        [self.verified removeObject:sender];
    }
}

- (void)execute:(id)sender forEvent:(UIEvent *)event
{
    BOOL shouldTrack;
    if (self.verifyEvent != 0 && self.verifyEvent != self.controlEvent) {
        shouldTrack = [self.verified containsObject:sender];
    } else {
        shouldTrack = [self verifyControlMatchesPath:sender];
    }
    if (shouldTrack) {
        NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
        if (self.attributes) {
            [p addEntriesFromDictionary:[self.attributes parse]];
        }
        if ([Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]
            && [Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]) {
            NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionKeys"]];
            NSDictionary *values = [NSDictionary dictionaryWithDictionary:[Sugo sharedInstance].sugoConfiguration[@"DimensionValues"]];
            NSMutableString *contentInfo = [[self contentInfoOfView:sender] mutableCopy];
            NSString *eventLabel = [NSString string];
            if (contentInfo.length > 0) {
                eventLabel = [contentInfo substringToIndex:(contentInfo.length - 1)];
            }
            p[keys[@"EventLabel"]] = eventLabel;
            if (self.controlEvent == UIControlEventEditingDidBegin) {
                p[keys[@"EventType"]] = values[@"focus"];
            } else {
                p[keys[@"EventType"]] = values[@"click"];
            }
//            p[keys[@"PagePath"]] = NSStringFromClass([[UIViewController sugoCurrentUIViewController] class]);
//            if ([SugoPageInfos global].infos.count > 0) {
//                for (NSDictionary *info in [SugoPageInfos global].infos) {
//                    if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
//                        p[keys[@"PageName"]] = info[@"page_name"];
//                        if (info[@"page_category"]) {
//                            p[keys[@"PageCategory"]] = info[@"page_category"];
//                        }
//                    }
//                }
//            }
        }
        [[self class] track:[self eventID] eventName:[self eventName] properties:p];
    }
}

#pragma mark -- NSCoder

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:@(_controlEvent) forKey:@"controlEvent"];
    [aCoder encodeObject:@(_verifyEvent) forKey:@"verifyEvent"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _controlEvent = [[aDecoder decodeObjectForKey:@"controlEvent"] unsignedIntegerValue];
        _verifyEvent = [[aDecoder decodeObjectForKey:@"verifyEvent"] unsignedIntegerValue];
    }
    return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[MPUIViewBinding class]]) {
        return NO;
    } else {
        return [super isEqual:other] && self.controlEvent == ((MPUIViewBinding *)other).controlEvent && self.verifyEvent == ((MPUIViewBinding *)other).verifyEvent;
    }
}

- (NSUInteger)hash {
    return [super hash] ^ self.controlEvent ^ self.verifyEvent;
}

@end
