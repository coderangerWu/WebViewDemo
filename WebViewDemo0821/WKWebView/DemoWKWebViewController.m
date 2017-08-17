//
//  DemoWKWebViewController.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/16.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "DemoWKWebViewController.h"
#import <WebKit/WebKit.h>
#import "WebViewHelper.h"

@interface WKScriptMessageHandler : NSObject<WKScriptMessageHandler>
@property (nonatomic, strong) WebViewHelper *helper;
@end
@implementation WKScriptMessageHandler

- (instancetype)initWithHelper:(WebViewHelper *)helper
{
    self = [super init];
    if (self) {
        _helper = helper;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"testClick"]) {
        [self.helper handleBridgeMessage:message.body];
    }
}

@end

@interface DemoWKWebViewController ()<WKNavigationDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WebViewHelper *helper;
@end

@implementation DemoWKWebViewController

- (void)dealloc
{
    self.webView.navigationDelegate = nil;
}

- (WebViewHelper *)helper
{
    if (!_helper) {
        WebViewHelper *helper = [[WebViewHelper alloc] init];
        _helper = helper;
    }
    return _helper;
}

- (WKWebView *)webView
{
    if (!_webView) {
        // Configuration
        WKScriptMessageHandler *messageHandler = [[WKScriptMessageHandler alloc] initWithHelper:self.helper];
        WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
        // 注册testClick事件
        [wkWebConfig.userContentController addScriptMessageHandler:messageHandler name:@"testClick"];
        
        // WebView
        CGRect webviewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y+self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
        WKWebView *webView = [[WKWebView alloc] initWithFrame:webviewRect configuration:wkWebConfig];
        webView.navigationDelegate = self;
        
        _webView = webView;
    }
    return _webView;
}

#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"WKWebView";
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Navi
    UIBarButtonItem *naviBack = [[UIBarButtonItem alloc] initWithTitle:@"返回"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem = naviBack;
    
    // User Agent
    [self setUserAgent];
    
    // WebView
    [self.view addSubview:self.webView];
    
    // Load Request
    [self loadLocalFile];
//    [self loadRemoteURL];
}

- (void)loadLocalFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bridge" ofType:@"html"];
    if (!path) return;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        // iOS9. One year later things are OK.
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    } else {
        // iOS8. Things can be workaround-ed
        //   Brave people can do just this
        //   fileURL = try! pathForBuggyWKWebView8(fileURL)
        //   webView.loadRequest(NSURLRequest(URL: fileURL))
        
        NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:path]];
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
        [self.webView loadRequest:request];
    }
}

- (void)loadRemoteURL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]];
    [self.webView loadRequest:request];
}

- (void)setUserAgent
{
    if (![[NSUserDefaults standardUserDefaults] stringForKey:@"UIUserAgent" ]) {
        
        WKWebView *wkwebView = [[WKWebView alloc] initWithFrame:CGRectZero];
        [wkwebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable item, NSError * _Nullable error) {
            [[NSUserDefaults standardUserDefaults] setObject:item forKey:@"UIUserAgent"];
        }];
    }
    
    NSString *oldAgent = [[NSUserDefaults standardUserDefaults] stringForKey:@"UIUserAgent"];
    NSString *newAgent = [NSString stringWithFormat:@"%@ %@", oldAgent, @"DemoWKWebView"];
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

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    
    if ([url.scheme isEqualToString:@"fusion"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self.helper handleBridgeUrl:url];
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    __weak typeof(self) weakSelf = self;
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable item, NSError * _Nullable error) {
        if (item && [item isKindOfClass:[NSString class]]) {
            weakSelf.title = item;
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
