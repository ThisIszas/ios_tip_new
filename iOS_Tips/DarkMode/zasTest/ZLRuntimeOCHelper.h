//
//  ZLRuntimeOCHelper.h
//
//
//  Created by Zas on 2022/7/29.
//  Copyright © 2022 Zas. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZLRuntimeOCHelper : NSObject
+ (int)getPrivateIntValueForClass:(id)objectInstance className:(NSString *)className keyName:(NSString *)keyName;
@end

NS_ASSUME_NONNULL_END
