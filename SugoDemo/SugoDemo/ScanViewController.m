//
//  ScanViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "ScanViewController.h"
#import "SwitchModeViewController.h"

@interface ScanViewController () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIView *scanView;

@property (strong, nonatomic) AVCaptureDevice            *device;
@property (strong, nonatomic) AVCaptureDeviceInput       *input;
@property (strong, nonatomic) AVCaptureMetadataOutput    *output;
@property (strong, nonatomic) AVCaptureSession           *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;

@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupScanner];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupScanner {
    
    if (![self hasCameraPermission]) {
        return;
    }
    
    if (!self.scanView) {
        CGSize windowSize = [UIScreen mainScreen].bounds.size;
        
        CGSize scanSize = CGSizeMake(windowSize.width*3/4, windowSize.width*3/4);
        CGRect scanRect = CGRectMake((windowSize.width-scanSize.width)/2, (windowSize.height-scanSize.height)/2, scanSize.width, scanSize.height);
        
        scanRect = CGRectMake(scanRect.origin.y/windowSize.height, scanRect.origin.x/windowSize.width, scanRect.size.height/windowSize.height,scanRect.size.width/windowSize.width);
        
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        
        self.output = [[AVCaptureMetadataOutput alloc]init];
        [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        self.session = [[AVCaptureSession alloc]init];
        [self.session setSessionPreset:([UIScreen mainScreen].bounds.size.height<500)?AVCaptureSessionPreset640x480:AVCaptureSessionPresetHigh];
        [self.session addInput:self.input];
        [self.session addOutput:self.output];
        self.output.metadataObjectTypes=@[AVMetadataObjectTypeQRCode];
        self.output.rectOfInterest = scanRect;
        
        self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
        self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.preview.frame = [UIScreen mainScreen].bounds;
        [self.view.layer insertSublayer:self.preview atIndex:0];
        
        self.scanView = [UIView new];
        [self.view addSubview:self.scanView];
        self.scanView.frame = CGRectMake(0, 0, scanSize.width, scanSize.height);
        self.scanView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
        self.scanView.layer.borderColor = [UIColor colorWithRed:117/255 green:102/255 blue:1 alpha:1].CGColor;
        self.scanView.layer.borderWidth = 1;
    }
    
    [self.session startRunning];
}

- (BOOL)hasCameraPermission {
    BOOL isHavePermission = NO;
    if ([AVCaptureDevice respondsToSelector:@selector(authorizationStatusForMediaType:)])
    {
        AVAuthorizationStatus permission =
        [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (permission) {
            case AVAuthorizationStatusAuthorized:
                isHavePermission = YES;
                break;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
            case AVAuthorizationStatusNotDetermined:
                break;
        }
    }
    
    return isHavePermission;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    
    if ( (metadataObjects.count == 0) )
    {
        return;
    }
    
    if (metadataObjects.count > 0) {
        
        [self.session stopRunning];
        
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects.firstObject;
        
        SwitchModeViewController *smvc = [self.storyboard instantiateViewControllerWithIdentifier:@"SwitchMode"];
        smvc.urlString = metadataObject.stringValue;
        [self.navigationController pushViewController:smvc animated:YES];
    }
}

@end










