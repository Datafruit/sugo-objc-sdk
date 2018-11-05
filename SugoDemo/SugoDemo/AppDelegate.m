//
//  AppDelegate.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "AppDelegate.h"
@import Sugo;


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self initSugo];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    
    return [[Sugo sharedInstance] handleURL:url];
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//    
//}

//- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
//    
//}

//- (void)initSugo {
//    NSString *projectID = @"com_H1bIzqK2SZ_project_r1HAty5zM"; // 项目ID
//    NSString *appToken = @"1a9f8bed75f2df2489dd272e03a92596"; // 应用Token
//    SugoBindingsURL = @"http://58.63.110.97:2270"; // 设置获取绑定事件配置的URL，端口默认为8000
//    SugoCollectionURL = @"http://58.63.110.97:2271"; // 设置传输绑定事件的网管URL，端口默认为80
//    SugoCodelessURL = @"ws://58.63.110.97:2227"; // 设置连接可视化埋点的URL，端口默认为8887
//    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
//    [[Sugo sharedInstance] setEnableLogging:YES]; // 如果需要查看SDK的Log，请设置为true
//    [[Sugo sharedInstance] setFlushInterval:5]; // 被绑定的事件数据往服务端上传的事件间隔，单位是秒，如若不设置，默认时间是60秒
//    [[Sugo sharedInstance] setCacheInterval:60]; // 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
//}

//- (void)initSugo {
//    NSString *projectID = @"com_SJLnjowGe_project_HyErw0VBW"; // 项目ID
//    NSString *appToken = @"4216f38f4959de6f2342918d0e3eace1"; // 应用Token
//    SugoBindingsURL = @"http://192.168.0.77:8080"; // 设置获取绑定事件配置的URL，端口默认为8000
//    SugoCollectionURL = @"http://collect.sugo.io"; // 设置传输绑定事件的网管URL，端口默认为80
//    SugoCodelessURL = @"ws://192.168.0.77:8887"; // 设置连接可视化埋点的URL，端口默认为8887
//    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
//    [[Sugo sharedInstance] setEnableLogging:YES]; // 如果需要查看SDK的Log，请设置为true
//    [[Sugo sharedInstance] setFlushInterval:600]; // 被绑定的事件数据往服务端上传的事件间隔，单位是秒，如若不设置，默认时间是60秒
//    [[Sugo sharedInstance] setCacheInterval:600]; // 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
//}

- (void)initSugo {
    NSString *projectID = @"com_H1bIzqK2SZ_project_r1HAty5zM"; // 项目ID
    NSString *appToken = @"1a9f8bed75f2df2489dd272e03a92596"; // 应用Token
    SugoBindingsURL = @"http://58.63.110.97:2270"; // 设置获取绑定事件配置的URL，端口默认为8000
    SugoCollectionURL = @"http://58.63.110.97:2271"; // 设置传输绑定事件的网管URL，端口默认为80
    SugoCodelessURL = @"ws://58.63.110.97:2227"; // 设置连接可视化埋点的URL，端口默认为8887
    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
    [[Sugo sharedInstance] setEnableLogging:YES]; // 如果需要查看SDK的Log，请设置为true
    [[Sugo sharedInstance] setFlushInterval:5]; // 被绑定的事件数据往服务端上传的事件间隔，单位是秒，如若不设置，默认时间是60秒
    [[Sugo sharedInstance] setCacheInterval:60]; // 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
}

//- (void)initSugo {
//    NSString *projectID = @"com_SJLnjowGe_project_rJclMJ11M"; // 项目ID
//    NSString *appToken = @"835cc6178adb433914ad1842cccab660"; // 应用Token
//    SugoBindingsURL = @"http://192.168.1.100:8080"; // 设置获取绑定事件配置的URL，端口默认为8000
//    SugoCollectionURL = @"http://collect.sugo.io"; // 设置传输绑定事件的网管URL，端口默认为80
//    SugoCodelessURL = @"ws://192.168.1.100:8887"; // 设置连接可视化埋点的URL，端口默认为8887
//    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
//    [[Sugo sharedInstance] setEnableLogging:YES]; // 如果需要查看SDK的Log，请设置为true
//    [[Sugo sharedInstance] setFlushInterval:5]; // 被绑定的事件数据往服务端上传的事件间隔，单位是秒，如若不设置，默认时间是60秒
//    [[Sugo sharedInstance] setCacheInterval:60]; // 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
//}

//- (void)initSugo {
//    NSString *projectID = @"Add_Your_Project_ID_Here";
//    NSString *appToken = @"Add_Your_App_Token_Here";
////    SugoBindingsURL = @"";
////    SugoCollectionURL = @"";
////    SugoCodelessURL = @"";
//    NSDictionary *priorityProperties = @{};
//    [Sugo registerPriorityProperties:priorityProperties];
//    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
//    [[Sugo sharedInstance] setEnableLogging:YES];
//    [[Sugo sharedInstance] setFlushInterval:5]; // default to 60
//    [[Sugo sharedInstance] setCacheInterval:60];// default to 3600
//}

@end
