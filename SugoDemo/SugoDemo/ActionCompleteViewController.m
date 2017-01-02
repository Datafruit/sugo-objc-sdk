//
//  ActionCompleteViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "ActionCompleteViewController.h"

@interface ActionCompleteViewController ()

@property (weak, nonatomic) IBOutlet UIView *popupView;
@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end

@implementation ActionCompleteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ActionComplete";
    
    self.popupView.clipsToBounds = YES;
    self.popupView.layer.cornerRadius = 6;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tap];
    self.actionLabel.text = self.actionStr;
    self.descLabel.text = self.descStr;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            NSLog(@"ActionCompleteViewController Dismiss");
        }];
    });
}

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"ActionCompleteViewController Dismiss");
    }];
}


@end
