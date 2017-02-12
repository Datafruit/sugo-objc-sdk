//
//  WKWebViewController.m
//  SugoDemo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import "WKWebViewController.h"

@interface WKWebViewController ()

@property (atomic, strong) WKWebView *webView;

@end

@implementation WKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"WKWebView";
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame
                                      configuration:configuration];
    self.webView.navigationDelegate = self;
    NSURL *url = [[NSURL alloc] initWithString:@"https://www.jd.com/"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

@end
