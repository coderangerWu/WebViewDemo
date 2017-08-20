//
//  DemoWKWebViewController.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/16.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "DemoWKWebViewController.h"
#import "WebViewHelper.h"

#import <WebKit/WebKit.h>

@interface WKScriptMessageHandler : NSObject<WKScriptMessageHandler,WKUIDelegate>
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
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) WebViewHelper *helper;
@end

@implementation DemoWKWebViewController

- (void)dealloc
{
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    
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
        WKWebViewConfiguration *webConfigutation = [[WKWebViewConfiguration alloc] init];
        
        // 进程池，不设置使用默认的pool
        WKProcessPool *processPool = [[WKProcessPool alloc] init];
        webConfigutation.processPool = processPool;
        
        // wkwebview偏好设置
        WKPreferences *preference = [[WKPreferences alloc]init];
//        preference.javaScriptEnabled = NO;
        webConfigutation.preferences = preference;
        
        // 注册testClick事件
        WKScriptMessageHandler *messageHandler = [[WKScriptMessageHandler alloc] initWithHelper:self.helper];
        [webConfigutation.userContentController addScriptMessageHandler:messageHandler name:@"testClick"];
        
        // WebView
        CGRect webviewRect = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y+self.navigationController.navigationBar.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
        WKWebView *webView = [[WKWebView alloc] initWithFrame:webviewRect configuration:webConfigutation];
        webView.navigationDelegate = (id)self;
        webView.UIDelegate = (id)self;
        
        _webView = webView;
    }
    return _webView;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.webView.frame.size.width, 2.0)];
        progressView.backgroundColor = [UIColor greenColor];
        progressView.progress = 0.0;
        _progressView = progressView;
    }
    return _progressView;
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
//    [self setUserAgent];
    
    // WebView
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.view addSubview:self.webView];
    
    // Progress View
    [self.webView addSubview:self.progressView];
    [self.webView bringSubviewToFront:self.progressView];
    
    // Load Request
    [self loadLocalFile];
//    [self loadRemoteURL];
}

- (void)loadLocalFile
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WKWebVewBridge" ofType:@"html"];
    if (!path) return;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        // iOS9. One year later things are OK.
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    } else {
        NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:path]];
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
        [self.webView loadRequest:request];
    }
}

- (void)loadRemoteURL
{
    NSString *url = @"https://webkit.org/perf/sunspider/sunspider.html";
    url = @"https://webkit.org/blog/3395/speedometer-benchmark-for-web-app-responsiveness/";
    url = @"https://www.baidu.com/";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
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
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    NSURL *url = navigationAction.request.URL;
    
    if ([url.scheme isEqualToString:@"fusion"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        [self.helper handleBridgeUrl:url];
    }
    
    self.progressView.hidden = NO;
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    // 执行 document.title 获取 title 后赋值
//    __weak typeof(self) weakSelf = self;
//    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable item, NSError * _Nullable error) {
//        if (item && [item isKindOfClass:[NSString class]]) {
//            weakSelf.title = item;
//        }
//    }];
    
    // 直接读取 webview 的 title 属性
    self.title = webView.title;
    
    // 设置 cookie
    [self setCookieForWKWebView];
    
    self.progressView.hidden = YES;
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
        
    }
    
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling,nil);
}

-(void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    
    self.progressView.hidden = YES;
}

#pragma mark - WKUIDelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
    WKWebView *newWekView = [[WKWebView alloc] initWithFrame:webView.frame configuration:configuration];
    return newWekView;
}

- (void)webViewDidClose:(WKWebView *)webView
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    completionHandler();
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler
{
    completionHandler(YES);
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    completionHandler(@"123");
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

#pragma mark -
- (void)setCookieForWKWebView
{
    //取出cookie
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    //js函数
    NSString *JSFuncString =
    @"function setCookie(name,value,expires)\
    {\
    var oDate=new Date();\
    oDate.setDate(oDate.getDate()+expires);\
    document.cookie=name+'='+value+';expires='+oDate+';path=/'\
    }\
    function getCookie(name)\
    {\
    var arr = document.cookie.match(new RegExp('(^| )'+name+'=([^;]*)(;|$)'));\
    if(arr != null) return unescape(arr[2]); return null;\
    }\
    function delCookie(name)\
    {\
    var exp = new Date();\
    exp.setTime(exp.getTime() - 1);\
    var cval=getCookie(name);\
    if(cval!=null) document.cookie= name + '='+cval+';expires='+exp.toGMTString();\
    }";
    
    //拼凑js字符串
    NSMutableString *JSCookieString = JSFuncString.mutableCopy;
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        NSString *excuteJSString = [NSString stringWithFormat:@"setCookie('%@', '%@', 1);", cookie.name, cookie.value];
        [JSCookieString appendString:excuteJSString];
    }
    //执行js
    [self.webView evaluateJavaScript:JSCookieString completionHandler:nil];
}

- (void)clearCaches
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        
        NSSet *websiteDataTypes
        
        = [NSSet setWithArray:@[
                                
                                WKWebsiteDataTypeDiskCache,
                                
                                //WKWebsiteDataTypeOfflineWebApplicationCache,
                                
                                WKWebsiteDataTypeMemoryCache,
                                
                                //WKWebsiteDataTypeLocalStorage,
                                
                                //WKWebsiteDataTypeCookies,
                                
                                //WKWebsiteDataTypeSessionStorage,
                                
                                //WKWebsiteDataTypeIndexedDBDatabases,
                                
                                //WKWebsiteDataTypeWebSQLDatabases
                                
                                ]];
        
        //// All kinds of data
        
        //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        
        //// Date from
        
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        
        //// Execute
        
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            
            // Done
            
        }];
        
    } else {
        
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        
        NSError *errors;
        
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        
    }
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"title"]) {
        self.title = ((WKWebView *)object).title;
    } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.progress = ((WKWebView *)object).estimatedProgress;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
