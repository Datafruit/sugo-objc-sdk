//
//  BindingUtils.m
//  Sugo
//
//  Created by 陈宇艺 on 2019/1/14.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "BindingUtils.h"
#import "Sugo.h"
#import "ExceptionUtils.h"
@implementation BindingUtils

+(NSMutableDictionary *)requireExtraAttrWithValue:(NSDictionary *)classAttr p:(NSMutableDictionary *)p view:(UIView *)view indexPath:(NSIndexPath *)indexPath{
    @try {
        BOOL isTrue =  [[Sugo sharedInstance] getStartExtraAttrFuncion];
        if (!isTrue) {
            return p;
        }
    
        for (NSString *key in classAttr){
            NSString *value = classAttr[key];
            NSArray *array = [value componentsSeparatedByString:@","];
            NSString *data = @"";
            for(int i=0;i<array.count;i++){
                id attr=nil;
                if ([array[i] isEqualToString:@"text"]) {
                    attr=[self requireTextFromView:view indexPath:indexPath];
                }else{
                     attr = [view valueForKey:array[i]];
                }
                if (i>0) {
                    data = [data stringByAppendingString:[NSString stringWithFormat:@";%@",attr]];
                }else{
                    data = [data stringByAppendingString:[NSString stringWithFormat:@"%@",attr]];
                }
            }
            p[key] = data;
        }
        return p;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSMutableDictionary alloc]init];
    }
}


+(NSString *)requireTextFromView:(UIView *)view indexPath:(NSIndexPath *)indexPath{
    @try {
        NSString *str=nil;
        NSMutableArray *array = [[NSMutableArray alloc]init];
        if ([view isKindOfClass:[UITextView class]]) {
            UITextView *textView = (UITextView *)view;
            array = [self contentInfoOfView:textView];
        }else if([view isKindOfClass:[UITableView class]]){
            UITableView *tableView = (UITableView *)view;
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            array = [self contentInfoOfView:cell];
        }else if([view isKindOfClass:[UICollectionView class]]){
            UICollectionView *collectionView = (UICollectionView *)view;
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            array = [self contentInfoOfView:cell];
        }else{
            array = [self contentInfoOfView:view];
        }
        str = [array componentsJoinedByString:@","];
        return str;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return @"";
    }
}

+ (NSMutableArray *)contentInfoOfView:(UIView *)view
{
    NSMutableArray *array = [[NSMutableArray alloc]init];
    @try {
        
    //    NSMutableString *infos = [NSMutableString string];
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
                [array addObject:label];
            }
            [array addObjectsFromArray:[self contentInfoOfView:subview]];
    //        [infos appendString:[self contentInfoOfView:subview]];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        
    }
    return array;
}

@end
