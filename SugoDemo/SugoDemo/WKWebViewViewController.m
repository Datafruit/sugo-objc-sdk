//
//  WKWebViewViewController.m
//  SugoDemo
//
//  Created by Zack on 20/3/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "WKWebViewViewController.h"

@interface WKWebViewViewController ()

@property (atomic, strong) WKWebView *webView;

@end

@implementation WKWebViewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.frame
                                      configuration:configuration];
    self.webView.navigationDelegate = self;
//    NSURL *url = [[NSURL alloc] initWithString:@"http://h5.chinagames.net/game/CUTV/GameHall.aspx"];
    NSURL *url = [[NSURL alloc] initWithString:@"http://jd.com"];	
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    [self.view addSubview:self.webView];
//    [self buildBtn];
    
}

-(void)buildBtn{
    CGRect screen = [[UIScreen mainScreen] bounds];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((screen.size.width-200)/2,300,200,50)];
    [btn setTitle:@"模态" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn setBackgroundColor:[UIColor blueColor]];
//    [btn addTarget:self action:@selector(touch:) forControlEvents:UIControlEventTouchUpInside];
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
