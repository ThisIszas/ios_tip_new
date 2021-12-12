//
//  ZLUrlAssetTestVC.m
//  DarkMode
//
//  Created by 郑立 on 2021/12/12.
//  Copyright © 2021 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "ZLUrlAssetTestVC.h"
#import <AVFoundation/AVFoundation.h>
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
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
