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
{
    NSString *_test2;
}
@property(nonatomic, strong) NSString *str111;
@property(nonatomic, weak) NSString *str1w11;
@property(atomic, weak) NSString *str1ssw11;
@end

@implementation ZLUrlAssetTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    char a = 'c';
    char *p = &a;
    printf("%p", p);
    printf("%c", *p);
    *p = 'o';
    printf("%c", *&a);
    // Do any additional setup after loading the view.
    
    void(^block1)(NSString *word) = ^(NSString *word){
        NSLog(@"hello world: %@", word);
    };
    
    block1(@"ddd");
    
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

//    class_addMethod([self class], @selector(gg), (IMP)testResolveMethod1, "v@:");
    unsigned int count;
    Method *m = class_copyMethodList([self class], &count);
    for(unsigned int i=0; i<count; i++){
        SEL selName = method_getName(m[i]);
        NSLog(@"%@", NSStringFromSelector(selName));
    }
    
    objc_property_t *pros = class_copyPropertyList([self class], &count);
    for(unsigned int i=0; i<count; i++){
        const char *name = property_getName(pros[i]);
        NSLog(@"%s %s", name, property_getAttributes(pros[i]));
    }
    
    Ivar *ivs = class_copyIvarList([self class], &count);
    for(unsigned int i=0; i<count; i++){
        const char *name = ivar_getName(ivs[i]);
        NSLog(@"%s", name);
        object_setIvar(self, ivs[i], @"11");
    }
    NSLog(@"%@", [self str111]);
}

- (void)testResolveMethod1{
    NSLog(@"1");
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
        return NO;
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
