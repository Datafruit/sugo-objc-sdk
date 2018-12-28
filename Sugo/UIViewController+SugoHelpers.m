//
//  UIViewController+SugoHelpers.m
//  Sugo
//
//  Created by Zack on 20/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "UIViewController+SugoHelpers.h"

@implementation UIViewController (SugoHelpers)

+ (UIViewController *)sugoCurrentViewController
{
    UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [UIViewController searchViewControllerFrom:viewController];
}

+ (UIViewController*)searchViewControllerFrom:(UIViewController*)viewController {
    
    if (viewController.presentedViewController) {
        
        // Return presented view controller
        return [UIViewController searchViewControllerFrom:viewController.presentedViewController];
        
    } else if ([viewController isKindOfClass:[UISplitViewController class]]) {
        
        // Return right hand side
        UISplitViewController* svc = (UISplitViewController*) viewController;
        if (svc.viewControllers.count > 0)
        return [UIViewController searchViewControllerFrom:svc.viewControllers.lastObject];
        else
        return viewController;
        
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        
        // Return top view
        UINavigationController* svc = (UINavigationController*) viewController;
        if (svc.viewControllers.count > 0)
        return [UIViewController searchViewControllerFrom:svc.topViewController];
        else
        return viewController;
        
    } else if ([viewController isKindOfClass:[UITabBarController class]]) {
        
        // Return visible view
        UITabBarController* svc = (UITabBarController*) viewController;
        if (svc.viewControllers.count > 0)
        return [UIViewController searchViewControllerFrom:svc.selectedViewController];
        else
        return viewController;
        
    } else {
        
        // Unknown view controller type, return last child view controller
        return viewController;
    }
    
}

+(UIViewController *)sugoCurrentViewController:(UIView *) view{
    id responder = view.nextResponder;
    while (![responder isKindOfClass: [UIViewController class]] && ![responder isKindOfClass: [UIWindow class]])
    {
        responder = [responder nextResponder];
    }
    if ([responder isKindOfClass: [UIViewController class]])
    {
        return (UIViewController *)responder ;
    }
    return nil;
}

@end
