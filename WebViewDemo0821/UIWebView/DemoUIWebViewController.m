//
//  DemoUIWebViewController.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/16.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "DemoUIWebViewController.h"
#import <NJKWebViewProgress/NJKWebViewProgress.h>
#import <NJKWebViewProgress/NJKWebViewProgressView.h>
#import "WebViewHelper.h"

@interface DemoUIWebViewController ()<UIWebViewDelegate,NJKWebViewProgressDelegate>
@property (nonatomic, strong) NJKWebViewProgress *progressProxy;
@property (nonatomic, strong) NJKWebViewProgressView *progressView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) WebViewHelper *helper;
@end

@implementation DemoUIWebViewController

- (void)dealloc
{
    self.webView.delegate = nil;
}

- (WebViewHelper *)helper
{
    if (!_helper) {
        WebViewHelper *helper = [[WebViewHelper alloc] init];
        _helper = helper;
    }
    return _helper;
}

- (NJKWebViewProgress *)progressProxy
{
    if (!_progressProxy) {
        // Proxy
        NJKWebViewProgress *progressProxy = [[NJKWebViewProgress alloc] init];
        progressProxy.webViewProxyDelegate = self;
        progressProxy.progressDelegate = self;
        _progressProxy = progressProxy;
    }
    return _progressProxy;
}

- (UIWebView *)webView
{
    if (!_webView) {
        CGRect webviewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y+self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
        UIWebView *webView = [[UIWebView alloc] initWithFrame:webviewRect];
        webView.delegate = self.progressProxy;
        _webView = webView;
    }
    return _webView;
}

- (NJKWebViewProgressView *)progressView
{
    if (!_progressView) {
        NJKWebViewProgressView *progressView = [[NJKWebViewProgressView alloc] initWithFrame:CGRectMake(0, 0, self.webView.frame.size.width, 2.0)];
        progressView.progress = 0.0;
        _progressView = progressView;
    }
    return _progressView;
}

#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"UIWebView";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Navi
    UIBarButtonItem *naviBack = [[UIBarButtonItem alloc]
                                initWithTitle:@"返回"
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem = naviBack;
    
    // WebView
    [self.view addSubview:self.webView];
    
    // Progress
    [self.webView addSubview:self.progressView];
    
//    [self loadLocalFile];
    [self loadRemoteURL];
    
    [self.webView bringSubviewToFront:self.progressView];
    
//    [self setUserAgent];
}

- (void)loadLocalFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bridge" ofType:@"html"];
    if (!path) return;
    
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    NSString *content = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:content baseURL:nil];
}

- (void)loadRemoteURL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com/"]];
    [self.webView loadRequest:request];
}

- (void)setUserAgent
{
    if (![[NSUserDefaults standardUserDefaults] stringForKey:@"UIUserAgent" ]) {
        
        UIWebView *awebView = [[UIWebView alloc] initWithFrame:CGRectZero];
        NSString *oldAgent = [awebView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        [[NSUserDefaults standardUserDefaults] setObject:oldAgent forKey:@"UIUserAgent"];
    }
    
    NSString *oldAgent = [[NSUserDefaults standardUserDefaults] stringForKey:@"UIUserAgent"];
    NSString *newAgent = [NSString stringWithFormat:@"%@ %@", oldAgent, @"DemoUIWebView"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent" : newAgent}];
}

#pragma mark - Tool
- (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    // Create "/temp/www" directory
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    // Now copy given file to the temp directory
    [fileManager removeItemAtURL:dstURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
    // Files in "/temp/www" load flawlesly :)
    return dstURL;
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    
    if ([url.scheme isEqualToString:@"fusion"]) {
        [self.helper handleBridgeUrl:url];
        return NO;
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title) {
        self.title = title;
    }
    
    [self.progressView setProgress:0];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    
}

#pragma mark - NJKWebViewProgressDelegate
- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [self.progressView setProgress:progress animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
