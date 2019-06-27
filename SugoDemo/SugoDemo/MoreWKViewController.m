//
//  MoreWKViewController.m
//  SugoDemo
//
//  Created by 陈宇艺 on 2019/6/27.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "MoreWKViewController.h"

@interface MoreWKViewController ()

@property (atomic, strong) WKWebView *webView;
@property (atomic, strong) WKWebView *webView2;
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation MoreWKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration2 = [[WKWebViewConfiguration alloc] init];
    self.webView2 = [[WKWebView alloc] initWithFrame:self.view.frame
                                       configuration:configuration2];
    self.webView2.navigationDelegate = self;
    NSURL *url2 = [[NSURL alloc] initWithString:@"https://h5.m.taobao.com/"];
    NSURLRequest *request2 = [[NSURLRequest alloc] initWithURL:url2];
    [self.webView2 loadRequest:request2];
    [self.view addSubview:self.webView2];
    
    
//    self.webView.hidden=true;
    
    
    
    
    [self.view bringSubviewToFront:_btn];
    // Do any additional setup after loading the view.
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (IBAction)btn:(id)sender {
    NSLog(@"ddddd");
    if (self.webView2.isHidden) {
        self.webView.hidden=true;
        self.webView2.hidden= false;
    }else{
        if (self.webView==nil) {
            WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
            self.webView = [[WKWebView alloc] initWithFrame:self.view.frame
                                              configuration:configuration];
            self.webView.navigationDelegate = self;
            NSURL *url = [[NSURL alloc] initWithString:@"https://jd.com/"];
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
            [self.webView loadRequest:request];
            [self.view addSubview:self.webView];
            [self.view bringSubviewToFront:_btn];
        }
        self.webView.hidden=false;
        self.webView2.hidden= true;
    }
}

@end
