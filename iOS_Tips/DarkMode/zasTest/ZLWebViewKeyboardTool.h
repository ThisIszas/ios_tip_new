//
//  ZLWebViewKeyboardTool.h
//
//  Created by Zheng Li on 2021/12/23.
//  Copyright © 2021 zas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLWebViewKeyboardTool : NSObject
- (void) hideWKWebviewKeyboardShortcutBar:(WKWebView *)webView;
@end

NS_ASSUME_NONNULL_END
