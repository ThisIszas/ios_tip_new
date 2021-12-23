//
//  ZLWebViewKeyboardTool.m
//
//  Created by Zheng Li on 2021/12/23.
//  Copyright © 2021 zas. All rights reserved.
//

#import "ZLWebViewKeyboardTool.h"
#import <objc/runtime.h>

// 实现
// 步骤一：创建一个_NoInputAccessoryView
@interface _NoInputAccessoryView : NSObject
@end
@implementation _NoInputAccessoryView
- (id)inputAccessoryView {
    return nil;
}
@end

@implementation ZLWebViewKeyboardTool
// 步骤二：去掉wkwebviewedone工具栏
- (void) hideWKWebviewKeyboardShortcutBar:(WKWebView *)webView {
    UIView *targetView;
    
    for (UIView *view in webView.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"WKContent"]) {
            targetView = view;
        }
    }
    if (!targetView) {
        return;
    }
    NSString *noInputAccessoryViewClassName = [NSString stringWithFormat:@"%@_NoInputAccessoryView", targetView.class.superclass];
    Class newClass = NSClassFromString(noInputAccessoryViewClassName);
    
    if(newClass == nil) {
        newClass = objc_allocateClassPair(targetView.class, [noInputAccessoryViewClassName cStringUsingEncoding:NSASCIIStringEncoding], 0);
        if(!newClass) {
            return;
        }
        
        Method method = class_getInstanceMethod([_NoInputAccessoryView class], @selector(inputAccessoryView));
        
        class_addMethod(newClass, @selector(inputAccessoryView), method_getImplementation(method), method_getTypeEncoding(method));
        
        objc_registerClassPair(newClass);
    }
    
    object_setClass(targetView, newClass);
}
@end
