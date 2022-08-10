//
//  ZLRuntimeOCHelper.m
//
//
//  Created by Zas on 2022/7/29.
//  Copyright © 2022 Zas. All rights reserved.
//

#import "ZLRuntimeOCHelper.h"
#import <objc/runtime.h>

@implementation ZLRuntimeOCHelper
+ (int)getPrivateIntValueForClass:(id)objectInstance className:(NSString *)className keyName:(NSString *)keyName{
    id classTmp = objc_getClass([className cStringUsingEncoding:NSASCIIStringEncoding] );
    
    unsigned int count = 0;
    Ivar *ivars = class_copyIvarList(classTmp, &count);
    int val = -100;
    
    for (int i = 0;i<count;i++) {
        Ivar ivar = ivars[i];
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if([ivarName isEqualToString: keyName]){
            val = ((int (*)(id, Ivar))object_getIvar)(objectInstance, ivar);
            break;
        }
    }
    
    return val;
}
@end
