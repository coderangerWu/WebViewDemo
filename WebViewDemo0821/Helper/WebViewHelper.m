//
//  WebViewHelper.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/17.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "WebViewHelper.h"
#import <UIKit/UIKit.h>

@interface WebViewHelper ()

@end

@implementation WebViewHelper

- (void)handleBridgeUrl:(NSURL *)url
{
    if (!url || ![url isKindOfClass:[NSURL class]]) return;
    
    NSString *funcName = url.host;
    NSString *param = url.query;
    
    NSString *message = [NSString stringWithFormat:@"function: %@ is called! param: %@",funcName,param];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    NSLog(@"function: %@ is called! param: %@",funcName,param);
}

- (void)handleBridgeMessage:(id)message
{
    if (!message || ![message isKindOfClass:[NSDictionary class]]) return;
    
    NSDictionary *data = (NSDictionary *)message;
    
    NSString *funcName = data[@"func"];
    NSDictionary *param = data[@"param"];
    
    NSString *msg = [NSString stringWithFormat:@"function: %@ is called! param: %@",funcName,param];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
    
    NSLog(@"function: %@ is called! param: %@",funcName,param);
}
@end
