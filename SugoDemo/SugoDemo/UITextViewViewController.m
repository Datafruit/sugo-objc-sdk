//
//  UITextViewViewController.m
//  SugoDemo
//
//  Created by Zack on 25/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "UITextViewViewController.h"

@interface UITextViewViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation UITextViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.textView.delegate = self;
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

- (void)textViewDidBeginEditing:(UITextView *)textView {
    
    NSLog(@"%s", __func__);
}

@end
