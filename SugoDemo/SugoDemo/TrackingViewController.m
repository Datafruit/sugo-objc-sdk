//
//  TrackingViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "TrackingViewController.h"
#import "ActionCompleteViewController.h"
@import Sugo;

@interface TrackingViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, atomic) NSArray *tableViewItems;

@end

@implementation TrackingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"Tracking";
    self.tableViewItems = @[@"Track w/o Properties",
                            @"Track w Properties",
                            @"Time Event 5secs",
                            @"Clear Timed Events",
                            @"Get Current SuperProperties",
                            @"Clear SuperProperties",
                            @"Register SuperProperties",
                            @"Register SuperProperties Once",
                            @"Register SP Once w Default Value",
                            @"Unregister SuperProperty"];
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
    NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
 
    switch (indexPath.item) {
        case 0:
            [SugoHelper trackEvent:@"Track Event!"];
            [descStr appendString:@"Event: \"Track Event!\""];
            break;
        case 1:
            p[@"Cool Property"] = @"Property Value";
            [SugoHelper trackEvent:@"Track Event With Properties!"
                                   properties:p];
            [descStr appendString:@"Event: \"Track Event With Properties!\"\nProperties: "];
            [descStr appendString:[p description]];
            break;
        case 2:
            [SugoHelper timeEvent:@"Timed Event"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SugoHelper trackEvent:@"Timed Event"];
            });
            [descStr appendString:@"Timed Event: \"Timed Event\""];
            break;
        case 3:
            [SugoHelper clearTimedEvents];
            [descStr appendString:@"Timed Events Cleared"];
            break;
        case 4:
            [descStr appendString:@"Super Properties:\n"];
            [descStr appendString:[[SugoHelper currentSuperProperties] description]];
            break;
        case 5:
            [SugoHelper clearSuperProperties];
            [descStr appendString:@"Cleared Super Properties"];
            break;
        case 6:
            p[@"Super Property 1"] = @1;
            p[@"Super Property 2"] = @"p2";
            p[@"Super Property 3"] = [NSDate date];
            p[@"Super Property 4"] = @{@"a": @"b"};
            p[@"Super Property 5"] = @[@3, @"a", [NSDate date]];
            p[@"Super Property 6"] = [[NSURL alloc] initWithString:@"https://sugo.io"];
            p[@"Super Property 7"] = [NSNull null];
            [SugoHelper registerSuperProperties:p];
            [descStr appendString:@"Properties: "];
            [descStr appendString:[p description]];
            break;
        case 7:
            p[@"Super Property 1"] = @2.3;
            [SugoHelper registerSuperPropertiesOnce:p];
            [descStr appendString:@"Properties: "];
            [descStr appendString:[p description]];
            break;
        case 8:
            p[@"Super Properrty 1"] = @1.2;
            [SugoHelper registerSuperPropertiesOnce:p defaultValue:@2.3];
            [descStr appendString:@"Properties: "];
            [descStr appendString:[p description]];
            [descStr appendString:@" with Default Value: 2.3"];
            break;
        case 9:
            [SugoHelper unregisterSuperProperty:@"Super Property 2"];
            [descStr appendString:@"Properties: "];
            [descStr appendString:@"Super Property 2"];
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










