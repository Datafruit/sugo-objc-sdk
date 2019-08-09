//
//  Sugo+HeatMap.m
//  Sugo
//
//  Created by 陈宇艺 on 2019/4/16.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "Sugo+HeatMap.h"
#import <UIKit/UIKit.h>
#import "macro.h"
#import "Sugo.h"
#import "MPSwizzler.h"
#import "projectMacro.h"
#import "SugoPageInfos.h"
#import "SugoPrivate.h"
@implementation Sugo (HeatMap)
-(void)buildApplicationMoveEvent{
     @try {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        bool isHeatMapFunc = [userDefaults boolForKey:@"isHeatMapFunc"];
        if(!isHeatMapFunc||![self openHeatMapFunc]){
            return;
        }
        void (^sendEventBlock)(id, SEL,id) = ^(id application, SEL command,UIEvent *event) {
            @try {
                UIApplication *app = (UIApplication *)application;
                if (!app) {
                    return;
                }
                NSSet *touches = [event allTouches];
                for (UITouch *touch in touches) {
                    switch ([touch phase]) {
                        case UITouchPhaseBegan:
                        {
                            CGPoint point = [touch locationInView:[UIApplication sharedApplication].keyWindow];
                            int x = point.x;
                            int y = point.y;
                            NSInteger serialNum = [self calculateTouch:x withY:y];
                            
                            NSMutableDictionary *p = [[NSMutableDictionary alloc]init];
                            NSDictionary *keys = [NSDictionary dictionaryWithDictionary:[[Sugo sharedInstance]requireSugoConfigurationWithKey:@"DimensionKeys"]];
                            NSDictionary *values = [NSDictionary dictionaryWithDictionary:[[Sugo sharedInstance]requireSugoConfigurationWithKey:@"DimensionValues"]];
                            NSString *pathName = [[Sugo sharedInstance] requireWebViewPath];
                            if (pathName==nil) {
                                pathName = @"";
                            }
                            if (pathName!=nil&&![pathName isEqualToString:@""]&& pathName.length>0) {
                                p[keys[@"PagePath"]] = pathName;
                            }
                            p[keys[@"OnclickPoint"]] = [NSString stringWithFormat:@"%ld",(long)serialNum];
                            if ([self isSubmitPointWithThisPage:pathName]) {
                                [[Sugo sharedInstance] trackEvent:values[@"ScreenTouch"] properties:p];
                            }
                            break;
                        }
                        case UITouchPhaseMoved:
                        case UITouchPhaseEnded:
                        case UITouchPhaseCancelled:
                            break;
                        default:
                            break;
                    }
                }
            } @catch (NSException *exception) {
                NSLog(@"%@",exception);
            }
        };
        
        [MPSwizzler swizzleSelector:@selector(sendEvent:)
                            onClass:[UIApplication class]
                          withBlock:sendEventBlock
                              named:[[NSUUID UUID] UUIDString]];
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
}

-(BOOL)openHeatMapFunc{
    bool isOk=false;
    @try {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            NSNumber * boolNum = info[@"isSubmitPoint"];
            BOOL isSubmitPoint = [boolNum boolValue];
            if (isSubmitPoint) {
                isOk = true;
                break;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return isOk;
}


-(BOOL)isSubmitPointWithThisPage:(NSString *)pathName{
    @try {
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
        if ([pathName isEqualToString:@""]) {
            pathName = self.superProperties[keys[@"PagePath"]];
        }
        if (!(keys&&[SugoPageInfos global].infos.count > 0)) {
            return false;
        }
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:pathName]) {
                NSNumber * boolNum = info[@"isSubmitPoint"];
                BOOL isSubmitPoint = [boolNum boolValue];
                if (isSubmitPoint) {
                    return true;
                }
                break;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return false;
}


-(NSInteger)calculateTouch:(float)x withY:(float) y{
    int columnNum = 36;
    int lineNum = 64;
    float areaWidth;
    float areaHeight;
    int serialNum = 0;
    @try {
        if (SUGOFULLSCREENH>SUGOFULLSCREENW) {//Vertical screen situation
            areaWidth = SUGOFULLSCREENW/columnNum;
            areaHeight = SUGOFULLSCREENH/lineNum;
        }else{//Landscape situation
            float ratio = (SUGOFULLSCREENH/columnNum)/(SUGOFULLSCREENW/lineNum);
            areaWidth = SUGOFULLSCREENW/columnNum;
            areaHeight = areaWidth*ratio;
            float statusHeight = 20;
            if (SUGOisiPhoneX) {
                statusHeight = 44;
            }
            float statusBarRatioHeight = areaHeight/((SUGOFULLSCREENW/lineNum)/statusHeight);
            y = y + statusBarRatioHeight;
        }
        float columnSerialValue =x/areaWidth;
        float lineNumSerialValue = y/areaHeight;
        int columnSerialNum = (columnSerialValue-(int)columnSerialValue)>0?(int)columnSerialValue+1:columnSerialValue;
        int lineNumSerialNum = (lineNumSerialValue-(int)lineNumSerialValue)>0?(int)lineNumSerialValue:lineNumSerialValue-1;
        serialNum = columnSerialNum + lineNumSerialNum*columnNum ;
        if(x==0){
            serialNum+=1;
        }
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return serialNum;
}
@end
