//
//  CodelessCommonViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "CodelessCommonViewController.h"

@interface CodelessCommonViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation CodelessCommonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Codeless";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSLog(@"%s: indexPath: %ld.%ld", __func__, indexPath.section, indexPath.row);

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    for (UIView *subView in cell.contentView.subviews) {
        if ([subView isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subView;
            label.text = [NSString stringWithFormat:@"Cell #%ld", (long)indexPath.item];
        }
    }
    
    return cell;
}


@end
