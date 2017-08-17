//
//  WebViewHelper.m
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/17.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import "WebViewHelper.h"

@interface WebViewHelper ()

@end

@implementation WebViewHelper

- (void)handleBridgeUrl:(NSURL *)url
{
    if (!url || ![url isKindOfClass:[NSURL class]]) return;
    
    NSString *funcName = url.host;
    NSString *param = url.query;
    NSLog(@"function: %@ is called! param: %@",funcName,param);
}

- (void)handleBridgeMessage:(id)message
{
    if (!message || ![message isKindOfClass:[NSDictionary class]]) return;
    
    NSDictionary *data = (NSDictionary *)message;
    
    NSString *funcName = data[@"func"];
    NSDictionary *param = data[@"param"];
    
    NSLog(@"function: %@ is called! param: %@",funcName,param);
}
@end
