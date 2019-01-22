//
//  UIControlViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "UIControlViewController.h"
#import "CustumButton.h"
@import Sugo;

@interface UIControlViewController ()
@property (weak, nonatomic) IBOutlet CustumButton *customBtn;

@end

@implementation UIControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _customBtn.buttonNum = 100;
    _customBtn.buttonTag=@"你好";
    _customBtn.isBoolText=YES;
    [_customBtn buildButtonPrivateAttr:@"内部变量"];
    // Do; any additional setup after loading the view.
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
        [[Sugo sharedInstance] trackFirstLoginWith:userId dimension: @"test_user_id"];
    }
}

- (IBAction)signOut:(UIButton *)sender {
    
    [[Sugo sharedInstance] untrackFirstLogin];
}
@end
