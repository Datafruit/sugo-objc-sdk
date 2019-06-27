//
//  MoreWebViewController.m
//  SugoDemo
//
//  Created by 陈宇艺 on 2019/6/27.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "MoreWebViewController.h"

@interface MoreWebViewController ()


@property (weak, nonatomic) IBOutlet UIWebView *WebView1;

@property (weak, nonatomic) IBOutlet UIWebView *webview2;

@end

@implementation MoreWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.WebView1.delegate = self;
    NSURL *url = [[NSURL alloc] initWithString:@"https://jd.com/"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.WebView1 loadRequest:request];
    
    self.webview2.delegate = self;
    NSURL *url2 = [[NSURL alloc] initWithString:@"http://search.m.dangdang.com/ddcategory.php"];
    NSURLRequest *request2 = [[NSURLRequest alloc] initWithURL:url2];
    [self.webview2 loadRequest:request2];
}

- (IBAction)btn:(id)sender {
    NSLog(@"dddd");
    if (self.WebView1.isHidden) {
        self.WebView1.hidden = false;
        self.webview2.hidden = true;
    }else{
        self.WebView1.hidden = true;
        self.webview2.hidden = false;
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    return YES;
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
