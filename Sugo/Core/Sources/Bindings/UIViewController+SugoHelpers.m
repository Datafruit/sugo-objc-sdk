//
//  UIViewController+SugoHelpers.m
//  Sugo
//
//  Created by Zack on 20/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "UIViewController+SugoHelpers.h"
#import "ExceptionUtils.h"
@implementation UIViewController (SugoHelpers)


+ (UITabBarController *)sugoCurrentUITabBarController {
    UIViewController *vc = [UIViewController sugoCurrentUIViewController];
    return vc.tabBarController;
}

+ (UINavigationController *)sugoCurrentUINavigationController {
    UIViewController *vc = [UIViewController sugoCurrentUIViewController];
    return vc.navigationController;
}

+ (UIViewController *)sugoCurrentUIViewController {
    @try {
        UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        return [UIViewController searchViewControllerFrom:viewController];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

+(UIViewController *)sugoCurrentUIViewController:(UIView *) view{
    @try {
        id responder = view.nextResponder;
        while (![responder isKindOfClass: [UIViewController class]] && ![responder isKindOfClass: [UIWindow class]])
        {
            responder = [responder nextResponder];
        }
        if ([responder isKindOfClass: [UIViewController class]])
        {
            return (UIViewController *)responder ;
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

+ (UIViewController*)searchViewControllerFrom:(UIViewController*)viewController {
    @try {
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
            
            if (viewController.childViewControllers.count > 0) {
                return [UIViewController searchViewControllerFrom:viewController.childViewControllers.lastObject];
            }
            
            // Unknown view controller type, return last child view controller
            return viewController;
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    
}

@end
