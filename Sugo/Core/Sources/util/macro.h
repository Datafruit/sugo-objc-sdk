//
//  macro.h
//  Sugo
//
//  Created by 陈宇艺 on 2018/12/12.
//  Copyright © 2018 sugo. All rights reserved.
//
#import <Foundation/Foundation.h>
#ifndef macro_h
#define macro_h

#define SUGOFULLSCREEN [UIScreen mainScreen].bounds   //获取屏幕大小
#define SUGOFULLSCREENW [UIScreen mainScreen].bounds.size.width    //获取屏幕宽度
#define SUGOFULLSCREENH [UIScreen mainScreen].bounds.size.height   //获取屏幕高度
#define SUGOSTATUSBARW [[UIApplication sharedApplication] statusBarFrame].size.width   //获取状态栏宽度
#define SUGOSTATUSBARH [[UIApplication sharedApplication] statusBarFrame].size.height  //获取状态栏高度
#define SUGONAVIGATIONBARW(navigationcontroller)  navigationcontroller.navigationBar.frame.size.width  //获取navigationbar宽度
#define SUGONAVIGATIONBARH(navigationcontroller)  navigationcontroller.navigationBar.frame.size.height  //获取navigationbar高度

#define SUGOTABBARHEIGHT(tabBar)   tabBar.frame.size.height     //获取tabbar高度


#pragma mark  -------------颜色相关-------------
#define SUGOkColor(r, g, b)         [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:1]
#define SUGOkColorAlpha(r, g, b, a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]
#define SUGOHexRGBAlpha(rgbValue, a)[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]
#define SUGOHexRGB(rgbValue)        [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SUGOkColorFromImage(imageName) [UIColor colorWithPatternImage:[UIImage imageNamed:imageName]]

#define SUGOHexRGBAlpha(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:(a)]
#define SUGOHexRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


#define SUGOWS(weakSelf)  __weak __typeof(&*self)weakSelf = self;


#pragma mark ------------字体大小(常规/粗体)----------------
#define SUGOBOLDSYSTEMFONT(FONTSIZE)    [UIFont boldSystemFontOfSize:FONTSIZE]
#define SUGOSYSTEMFONT(FONTSIZE)        [UIFont systemFontOfSize:FONTSIZE]



#pragma mark  ------------------------- 系统相关 -------------------------
// 当前版本
#define SUGOSSystemVersion  ([[UIDevice currentDevice] systemVersion])
#define SUGOFSystemVersion  ([SSystemVersion floatValue])
#define SUGODSystemVersion  ([SSystemVersion doubleValue])

#define SUGOAppVersion             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]  // 当前应用软件版本

#define SUGOAppBuildVersion               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]  // 当前应用版本号码


#define SUGODeviceSystemName [[UIDevice currentDevice] systemName]  //设备名称

#define SUGODeviceModel [[UIDevice currentDevice] model]  //手机型号

#define SUGOIdentifierNumber [[UIDevice currentDevice] advertisingIdentifier] //手机序列号

// 判断操作系统是否ios7\8
#define SUGOisIOS7          (FSystemVersion >= 7.0)
#define SUGOisIOS8          (FSystemVersion >= 8.0)

// 当前语言
#define SUGOCURRENTLANGUAGE ([[NSLocale preferredLanguages] objectAtIndex:0])

// 是否Retina屏
#define SUGOisRetina        ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)

// 是否iPhone5
#define SUGOisiPhone5       ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

// 是否iPhone6
#define SUGOisiPhone6       ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define SUGOisiPhone6Plus   ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)

#define SUGOisiPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)


// 是否iPad
#define SUGOisPad           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

//父类方法子类执行（类似Java的抽象方法）
#define SUGOAbstractMethodNotImplemented() \
@throw [NSException exceptionWithName:NSInternalInconsistencyException \
reason:[NSString stringWithFormat:@"You must override %@ in a subclass.", NSStringFromSelector(_cmd)] \
userInfo:nil]


#define SUGOkDegreesToRadians(degrees)  ((M_PI * degrees)/ 180)  //角度转弧度计算

#endif /* macro_h */
