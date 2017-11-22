//
//  UIControlViewController.h
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControlViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *userId;

- (IBAction)signIn:(UIButton *)sender;
- (IBAction)signOut:(UIButton *)sender;

@end
