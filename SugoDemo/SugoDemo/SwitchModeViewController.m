//
//  SwitchModeViewController.m
//  SugoDemo
//
//  Created by Zack on 21/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SwitchModeViewController.h"
@import Sugo;

@interface SwitchModeViewController ()

@end

@implementation SwitchModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)confirm:(id)sender {

    NSLog(@"url: %@", self.urlString);
    NSURL *url = [[NSURL alloc] initWithString:self.urlString];
    [[Sugo sharedInstance] connectToCodelessViaURL:url];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
