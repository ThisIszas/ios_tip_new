//
//  ZLUrlAssetTestVC.m
//  DarkMode
//
//  Created by 郑立 on 2021/12/12.
//  Copyright © 2021 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "ZLUrlAssetTestVC.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

@interface testRuntimeClass : NSObject
- (void)testUnknown;
@end

@implementation testRuntimeClass
- (void)testUnknown{
    NSLog(@"%s", "123");
}

@end


@interface ZLUrlAssetTestVC ()

@end

@implementation ZLUrlAssetTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSURL *asseturl = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    AVPlayerItem *item1 = [AVPlayerItem playerItemWithURL:asseturl];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item1];
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = CGRectMake(0, 100, 200, 200);
    
    [self.view.layer insertSublayer:playerLayer atIndex:0];
    [player play];
    
    NSLog(@"time duration: %lld %d", item1.duration.value, item1.duration.timescale);
    
    SEL unknownSel = NSSelectorFromString(@"testUnknown");
    [self performSelector:unknownSel];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

+ (BOOL)resolveInstanceMethod:(SEL)sel{
    NSString *selName = NSStringFromSelector(sel);
    if([selName isEqualToString: @"testUnknown"]){
        return true;
    }
    return [super resolveInstanceMethod:sel];;
}

- (id)forwardingTargetForSelector:(SEL)aSelector{
    NSString *selName = NSStringFromSelector(aSelector);
    if([selName isEqualToString: @"testUnknown"]){
        return nil;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    NSString *selName = NSStringFromSelector(aSelector);
    if([selName isEqualToString: @"testUnknown"]){
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];;
    }
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    SEL selector = anInvocation.selector;
    testRuntimeClass *testClass1 = [testRuntimeClass new];
    
    if([testClass1 respondsToSelector:selector]){
        [anInvocation invokeWithTarget:testClass1];
    }
    else{
        [anInvocation doesNotRecognizeSelector:selector];
    }
}

@end
