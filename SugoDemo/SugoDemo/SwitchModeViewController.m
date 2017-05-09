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

@property (weak, nonatomic) IBOutlet UILabel *switchLabel;

@property (atomic, strong) NSString *type;

@end

@implementation SwitchModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.type = [self handleURL];
    if ([self.type isEqualToString:@"heat"]) {
        self.switchLabel.text = @"切换至热图模式";
    } else if ([self.type isEqualToString:@"track"]){
        self.switchLabel.text = @"切换至可视化埋点模式";
    } else {
        self.switchLabel.text = @"信息错误，请重新扫码";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)handleURL {
    NSLog(@"url: %@", self.urlString);
    NSURL *url = [[NSURL alloc] initWithString:self.urlString];
    NSArray *rawQuerys = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *querys = [NSMutableDictionary dictionary];
    
    for (NSString *query in rawQuerys) {
        NSArray *item = [query componentsSeparatedByString:@"="];
        if (item.count != 2) {
            continue;
        }
        [querys addEntriesFromDictionary:@{[item firstObject]: [item lastObject]}];
    }
    NSString *type = [url.path componentsSeparatedByString:@"/"].lastObject;
    if (type && querys[@"sKey"]) {
        return type;
    }
    return @"";
}

- (IBAction)confirm:(id)sender {
    
    NSLog(@"url: %@", self.urlString);
    NSURL *url = [[NSURL alloc] initWithString:self.urlString];
    if ([self.type isEqualToString:@"heat"]) {
        [[Sugo sharedInstance] requestForHeatMapViaURL:url];
    } else if ([self.type isEqualToString:@"track"]){
        [[Sugo sharedInstance] connectToCodelessViaURL:url];
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)cancel:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
