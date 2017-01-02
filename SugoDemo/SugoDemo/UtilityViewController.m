//
//  UtilityViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "UtilityViewController.h"
#import "ActionCompleteViewController.h"
@import Sugo;

@interface UtilityViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, atomic) NSArray *tableViewItems;

@end

@implementation UtilityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Utility";
    self.tableViewItems = @[@"Create Alias",
                            @"Reset",
                            @"Archive",
                            @"Flush"];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *actionStr = [self.tableViewItems objectAtIndex:indexPath.item];
    NSMutableString *descStr = [[NSMutableString alloc] init];

    switch (indexPath.item) {
        case 0:
            [[Sugo sharedInstance] createAlias:@"New Alias"
                                 forDistinctID:[Sugo sharedInstance].distinctId];
            [descStr appendString:@"Alias: New Alias, from: "];
            [descStr appendString:[Sugo sharedInstance].distinctId];
            break;
        case 1:
            [[Sugo sharedInstance] reset];
            [descStr appendString:@"Reset Instance"];
            break;
        case 2:
            [[Sugo sharedInstance] archive];
            [descStr appendString:@"Archived Data"];
            break;
        case 3:
            [[Sugo sharedInstance] flush];
            [descStr appendString:@"Flushed Data"];
            break;
        default:
            break;
    }
    
    ActionCompleteViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ActionCompleteViewController"];
    vc.actionStr = actionStr;
    vc.descStr = descStr;
    [vc setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [vc setModalPresentationStyle:UIModalPresentationOverFullScreen];
    [self presentViewController:vc animated:YES completion:^{
        NSLog(@"Present ActionCompleteViewController");
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [self.tableViewItems objectAtIndex:indexPath.item];
    return cell;
}

@end
