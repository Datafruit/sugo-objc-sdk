//
//  HomeTableViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "HomeTableViewController.h"

@interface HomeTableViewController ()

@property (atomic, strong) NSTimer *deprecatedTimer;

@end

@implementation HomeTableViewController

static int deprecatedTimes = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.deprecatedTimer = [NSTimer scheduledTimerWithTimeInterval:5
                                                            target:self
                                                          selector:@selector(deprecate)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)scan:(id)sender {
    [self checkCameraPermissionForScan];
}


- (void)checkCameraPermissionForScan {
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)])
    {
        AVAuthorizationStatus permission = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (permission) {
            case AVAuthorizationStatusAuthorized:
                [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"Scan"] animated:YES];
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                [self presentViewController:[self createCameraAlertController] animated:YES completion:nil];
                break;
            case AVAuthorizationStatusNotDetermined:
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [self.navigationController pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"Scan"] animated:YES];
                        });
                    }
                }];
                break;
        }
    }
}

- (UIAlertController *)createCameraAlertController {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"相机权限不足"
                                                                             message:@"请到 设置->隐私->相机 中设置"
                                                                      preferredStyle:UIAlertControllerStyleAlert ];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"好"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
    [alertController addAction:cancelAction];
    return alertController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (IBAction)deprecatedAction:(id)sender {
    
    deprecatedTimes = deprecatedTimes + 1;
}

- (void)deprecate {
    
    if (deprecatedTimes > 5) {
        [self.deprecatedTimer invalidate];
        self.deprecatedTimer = nil;
        deprecatedTimes = 0;
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Deprecated" bundle:[NSBundle mainBundle]];
        UIViewController *vc = [sb instantiateInitialViewController];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        deprecatedTimes = 0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
