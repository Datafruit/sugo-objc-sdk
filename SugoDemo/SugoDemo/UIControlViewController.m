//
//  UIControlViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "UIControlViewController.h"
@import Sugo;

@interface UIControlViewController ()

@end

@implementation UIControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)signIn:(UIButton *)sender {
    
    NSString *userId = self.userId.text;
    if (userId) {
        [[Sugo sharedInstance] trackFirstLoginWith:userId];
    }
}

- (IBAction)signOut:(UIButton *)sender {
    
    [[Sugo sharedInstance] untrackFirstLogin];
}
@end
