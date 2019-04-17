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
@implementation Sugo (HeatMap)
-(void)buildApplicationMoveEvent{
    void (^sendEventBlock)(id, SEL,id) = ^(id application, SEL command,UIEvent *event) {
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
                    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
                    NSString *pathName = [ user objectForKey:CURRENTCONTROLLER];
                    if (pathName!=nil&&![pathName isEqualToString:@""]&& pathName.length>0) {
                        p[keys[@"PagePath"]] = pathName;
                    }
                    p[keys[@"OnclickPoint"]] = [NSString stringWithFormat:@"%ld",serialNum];
                    [[Sugo sharedInstance] trackEvent:values[@"ScreenTouch"] properties:p];
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
        
    };
    [MPSwizzler swizzleSelector:@selector(sendEvent:)
                        onClass:[UIApplication class]
                      withBlock:sendEventBlock
                          named:[[NSUUID UUID] UUIDString]];
}


-(NSInteger)calculateTouch:(float)x withY:(float) y{
    int columnNum = 36;
    int lineNum = 64;
    float areaWidth;
    float areaHeight;
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
    int serialNum = columnSerialNum + lineNumSerialNum*columnNum ;
    if(x==0){
        serialNum+=1;
    }
    return serialNum;
}
@end
