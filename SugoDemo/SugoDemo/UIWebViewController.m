//
//  UIWebViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "UIWebViewController.h"
@import Sugo;

@interface UIWebViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation UIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"UIWebView";
    
    self.webView.delegate = self;
    NSURL *url = [[NSURL alloc] initWithString:@"https://www.jd.com/"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    return [[Sugo sharedInstance] webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
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
