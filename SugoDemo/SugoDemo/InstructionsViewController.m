//
//  InstructionsViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "InstructionsViewController.h"

@interface InstructionsViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation InstructionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.webView.delegate = self;
    NSURL *url = [[NSURL alloc] initWithString:@"http://docs.sugo.io/"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
