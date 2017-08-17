//
//  WebViewHelper.h
//  WebViewDemo0821
//
//  Created by ranger on 2017/8/17.
//  Copyright © 2017年 ranger@didi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewHelper : NSObject

- (void)handleBridgeUrl:(NSURL *)url;

- (void)handleBridgeMessage:(id)message;

@end
