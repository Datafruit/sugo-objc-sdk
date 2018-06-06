//
//  UIViewController+SugoHelpers.h
//  Sugo
//
//  Created by Zack on 20/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (SugoHelpers)

+ (UIViewController *)sugoCurrentUIViewController;
+ (UINavigationController *)sugoCurrentUINavigationController;
+ (UITabBarController *)sugoCurrentUITabBarController;

@end
