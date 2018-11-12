//
//  DoubleWebViewController.m
//  SugoDemo
//
//  Created by 陈宇艺 on 2018/10/30.
//  Copyright © 2018年 sugo. All rights reserved.
//

#import "DoubleWebViewController.h"


#define FULLSCREEN [UIScreen mainScreen].bounds   //获取屏幕大小
#define FULLSCREENW [UIScreen mainScreen].bounds.size.width    //获取屏幕宽度
#define FULLSCREENH [UIScreen mainScreen].bounds.size.height   //获取屏幕高度
@interface DoubleWebViewController ()

@property (atomic, strong) WKWebView *webView1;
@property (atomic, strong) WKWebView *webView2;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (atomic,strong)UIWebView *uiWebView1;
@property (atomic,strong)UIWebView *uiWebView2;
@end

@implementation DoubleWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //    [self buildWebView];
    [self buildWkWebView];
}


-(void)buildWebView{
    _uiWebView1 =[[UIWebView alloc] initWithFrame:CGRectMake(0,0,_contentView.frame.size.width , _contentView.frame.size.height/2)];
    NSURL *url = [[NSURL alloc] initWithString:@"http://jd.com"];
    [_uiWebView1 loadRequest:[NSURLRequest requestWithURL:url]];
    _uiWebView1.delegate = self;
    [self.contentView addSubview:_uiWebView1];
    _uiWebView1.tag=1000;
    
    _uiWebView2 =[[UIWebView alloc] initWithFrame:CGRectMake(0, _contentView.frame.size.height/2,_contentView.frame.size.width , _contentView.frame.size.height/2)];
    NSURL *url2 = [[NSURL alloc] initWithString:@"http://h5.chinagames.net/game/CUTV/GameHall.aspx"];
    [_uiWebView2 loadRequest:[NSURLRequest requestWithURL:url2]];
    _uiWebView2.delegate = self;
    [self.contentView addSubview:_uiWebView2];
    NSInteger a= _uiWebView1.hash;
    _uiWebView2.tag=2000;
}


-(void)buildWkWebView{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.webView1 = [[WKWebView alloc] initWithFrame:CGRectMake(0,0, _contentView.frame.size.width , _contentView.frame.size.height/2)
                                       configuration:configuration];
    self.webView1.navigationDelegate = self;
    NSURL *url = [[NSURL alloc] initWithString:@"http://taobao.com"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView1 loadRequest:request];
    [self.contentView addSubview:self.webView1];
    NSInteger b= _webView1.hash;
    self.webView1.tag=1000;
    
    WKWebViewConfiguration *configuration2 = [[WKWebViewConfiguration alloc] init];
    self.webView2 = [[WKWebView alloc] initWithFrame:CGRectMake(0,_contentView.frame.size.height/2,_contentView.frame.size.width , _contentView.frame.size.height/2)
                                       configuration:configuration2];
    self.webView2.navigationDelegate = self;
    NSURL *url2 = [[NSURL alloc] initWithString:@"http://jd.com"];
    NSURLRequest *request2 = [[NSURLRequest alloc] initWithURL:url2];
    [self.webView2 loadRequest:request2];
    [self.contentView addSubview:self.webView2];
    NSInteger a= _webView2.hash;
    self.webView2.tag=2000;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
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
