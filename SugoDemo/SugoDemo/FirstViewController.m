//
//  FirstViewController.m
//  SugoDemo
//
//  Created by 陈宇艺 on 2018/11/6.
//  Copyright © 2018年 sugo. All rights reserved.
//

#import "FirstViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ThreeController.h"
@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self buildRightBtn];
    [self buildBtn];
    CGFloat labelWidth = 84;
    CGFloat labelHeight = 21;
    CGFloat labelTopView = 0;
    CGRect screen = [[UIScreen mainScreen] bounds];
    UILabel  *label = [[UILabel alloc] initWithFrame:CGRectMake((screen.size.width - labelWidth)/2 , 100, labelWidth, labelHeight)];
    label.text = @"Label";
    label.font = [UIFont systemFontOfSize:20.f];
    label.textColor = [UIColor purpleColor];
    //字体左右居中
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
}

-(void)buildBtn{
    CGRect screen = [[UIScreen mainScreen] bounds];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((screen.size.width-200)/2,300,200,50)];
    [btn setTitle:@"模态" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(touch:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)buildRightBtn{
    UIButton *leftbutton=[[UIButton alloc]initWithFrame:CGRectMake(0, 0, 80, 20)];
    //[leftbutton setBackgroundColor:[UIColor blackColor]];
    [leftbutton setTitle:@"扫一扫" forState:UIControlStateNormal];
    UIBarButtonItem *rightitem=[[UIBarButtonItem alloc]initWithCustomView:leftbutton];
    self.navigationItem.rightBarButtonItem=rightitem;
    [leftbutton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [leftbutton addTarget:self
                          action:@selector(BtnClick:)
                forControlEvents:UIControlEventTouchUpInside];
}

-(void)touch:(UIButton *)btn{
    UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ThreeController *controller = [story instantiateViewControllerWithIdentifier:@"ThreeController"];
    [self.navigationController presentViewController:controller animated:YES completion:nil];
}

- (void)BtnClick:(UIButton *)btn
{
    [self checkCameraPermissionForScan];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)checkCameraPermissionForScan {
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)])
    {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        AVAuthorizationStatus permission = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (permission) {
            case AVAuthorizationStatusAuthorized:
                
                [self.navigationController pushViewController:[story instantiateViewControllerWithIdentifier:@"Scan"] animated:YES];
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                [self presentViewController:[self createCameraAlertController] animated:YES completion:nil];
                break;
            case AVAuthorizationStatusNotDetermined:
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    if (granted) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            [self.navigationController pushViewController:[story instantiateViewControllerWithIdentifier:@"Scan"] animated:YES];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
