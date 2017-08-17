//
//  ViewController.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/16.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "ViewController.h"
#import "DemoUIWebViewController.h"
#import "DemoWKWebViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *datas;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"WebView Demo";
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.datas = @[
                   @"UIWebView",
                   @"WKWebView"
                   ];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row<0 || indexPath.row>self.datas.count-1) return nil;
    
    static NSString *WebViewDemoCellIdentifier = @"WebViewDemoCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WebViewDemoCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:WebViewDemoCellIdentifier];
    }
    
    NSString *text = self.datas[indexPath.row];
    cell.textLabel.text = text;
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row<0 || indexPath.row>self.datas.count-1) return;
    
    NSString *text = self.datas[indexPath.row];
    if ([text isEqualToString:@"UIWebView"]) {
        DemoUIWebViewController *webVC = [[DemoUIWebViewController alloc] init];
        [self.navigationController pushViewController:webVC animated:YES];
    } else if ([text isEqualToString:@"WKWebView"]) {
        DemoWKWebViewController *webVC = [[DemoWKWebViewController alloc] init];
        [self.navigationController pushViewController:webVC animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
