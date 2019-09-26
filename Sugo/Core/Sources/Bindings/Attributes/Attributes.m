//
//  Attributes.m
//  Sugo
//
//  Created by Zack on 9/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "Attributes.h"
#import "MPObjectSelector.h"
#import <UIKit/UIKit.h>
#import "MPLogger.h"
#import "ExceptionUtils.h"

@implementation Attributes

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    if (self = [self init]) {
        self.paths = [attributes mutableCopy];
    }
    return self;
}

- (NSDictionary *)parse
{
    
    @try {
        NSMutableDictionary *aValues = [[NSMutableDictionary alloc] init];
        NSDictionary *aObjects = [self parsePaths];
        for (NSString *key in aObjects.allKeys) {
            for (id object in (NSArray *)aObjects[key]) {
                if ([object isKindOfClass:[UISearchBar class]]) {
                    MPLogDebug(@"attributes: UISearchBar");
                    if (((UISearchBar *)object).text) {
                        [aValues addEntriesFromDictionary:@{key: ((UISearchBar *)object).text}];
                    } else {
                        [aValues addEntriesFromDictionary:@{key: @""}];
                    }
                } else if ([object isKindOfClass:[UIButton class]]) {
                    MPLogDebug(@"attributes: UIButton");
                    if (((UIButton *)object).titleLabel) {
                        [aValues addEntriesFromDictionary:@{key: ((UIButton *)object).titleLabel.text}];
                    } else {
                        [aValues addEntriesFromDictionary:@{key: @""}];
                    }
                } else if ([object isKindOfClass:[UIDatePicker class]]) {
                    MPLogDebug(@"attributes: UIDatePicker");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%@", ((UIDatePicker *)object).date]}];
                } else if ([object isKindOfClass:[UISegmentedControl class]]) {
                    MPLogDebug(@"attributes: UISegmentedControl");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%ld", (long)((UISegmentedControl *)object).selectedSegmentIndex]}];
                } else if ([object isKindOfClass:[UISlider class]]) {
                    MPLogDebug(@"attributes: UISlider");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%f", ((UISlider *)object).value]}];
                } else if ([object isKindOfClass:[UISwitch class]]) {
                    MPLogDebug(@"attributes: UISwitch");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%i", ((UISwitch *)object).isOn]}];
                } else if ([object isKindOfClass:[UITextField class]]) {
                    MPLogDebug(@"attributes: UITextField");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%@", ((UITextField *)object).text]}];
                } else if ([object isKindOfClass:[UITextView class]]) {
                    MPLogDebug(@"attributes: UITextView");
                    [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%@", ((UITextView *)object).text]}];
                } else {
                    MPLogDebug(@"attributes class: %@", NSStringFromClass([object classForCoder]));
                    aValues[key] = [NSString stringWithFormat:@"%@", self.paths[key]];
                }
                MPLogDebug(@"%@ = %@", key, aValues[key]);
                break;
            }
        }
        return aValues;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
    
}


- (NSDictionary *)parsePaths
{
    @try {
        NSMutableDictionary *aObjects = [[NSMutableDictionary alloc] init];
        for (NSString *key in self.paths.allKeys) {
            MPObjectSelector *p = [[MPObjectSelector alloc] initWithString:self.paths[key]];
            if ([UIApplication sharedApplication].keyWindow) {
                NSMutableArray *objects = [[NSMutableArray alloc] init];
                [objects addObjectsFromArray:[p selectFromRoot:[UIApplication sharedApplication].keyWindow]];
                [aObjects setObject:objects forKey:key];
            }
        }
        return aObjects;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
}

@end










