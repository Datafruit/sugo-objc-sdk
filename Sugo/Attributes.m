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
    NSMutableDictionary *aValues = [[NSMutableDictionary alloc] init];
    NSDictionary *aObjects = [self parsePaths];
    for (NSString *key in aObjects) {
        for (id object in (NSArray *)aObjects[key]) {
            
            if ([object isKindOfClass:[UISearchBar class]]) {
                NSLog(@"attributes: UISearchBar");
                if (((UISearchBar *)object).text) {
                    [aValues addEntriesFromDictionary:@{key: ((UISearchBar *)object).text}];
                } else {
                    [aValues addEntriesFromDictionary:@{key: @""}];
                }
            } else if ([object isKindOfClass:[UIButton class]]) {
                NSLog(@"attributes: UIButton");
                if (((UIButton *)object).titleLabel) {
                    [aValues addEntriesFromDictionary:@{key: ((UIButton *)object).titleLabel.text}];
                } else {
                    [aValues addEntriesFromDictionary:@{key: @""}];
                }
            } else if ([object isKindOfClass:[UIDatePicker class]]) {
                NSLog(@"attributes: UIDatePicker");
                [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%@", ((UIDatePicker *)object).date]}];
            } else if ([object isKindOfClass:[UISegmentedControl class]]) {
                NSLog(@"attributes: UISegmentedControl");
                [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%ld", (long)((UISegmentedControl *)object).selectedSegmentIndex]}];
            } else if ([object isKindOfClass:[UISlider class]]) {
                NSLog(@"attributes: UISlider");
                [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%f", ((UISlider *)object).value]}];
            } else if ([object isKindOfClass:[UISwitch class]]) {
                NSLog(@"attributes: UISwitch");
                [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%i", ((UISwitch *)object).isOn]}];
            } else if ([object isKindOfClass:[UITextField class]]) {
                NSLog(@"attributes: UITextField");
                [aValues addEntriesFromDictionary:@{key: [NSString stringWithFormat:@"%@", ((UITextField *)object).text]}];
            } else {
                NSLog(@"attributes class: %@", NSStringFromClass([object classForCoder]));
                aValues[key] = [NSString stringWithFormat:@"%@", self.paths[key]];
            }
            NSLog(@"%@ = %@", key, aValues[key]);
            
        }
    }
    return aValues;
}


- (NSDictionary *)parsePaths
{
    NSMutableDictionary *aObjects = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.paths) {
        MPObjectSelector *p = [[MPObjectSelector alloc] initWithString:self.paths[key]];
        if ([UIApplication sharedApplication].keyWindow.rootViewController) {
            NSMutableArray *objects = [[NSMutableArray alloc] init];
            [objects addObjectsFromArray:[p fuzzySelectFromRoot:[UIApplication sharedApplication].keyWindow.rootViewController]];
            [aObjects setObject:objects forKey:key];
        }
    }
    return aObjects;
}

@end










