//
//  ZLScroolView.m
//  DarkMode
//
//  Created by 郑立 on 2021/12/12.
//  Copyright © 2021 https://github.com/wsl2ls   ----- . All rights reserved.
//

#import "ZLScroolView.h"
@interface ZLScroolView()<UIScrollViewDelegate>
@property(strong, nonatomic) UIImageView *zoomImageView;
@end

@implementation ZLScroolView

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        self.maximumZoomScale = 5.0;
//        self.minimumZoomScale = 1.0;
//
//        [self addSubview:self.zoomImageView];
//    }
//    return self;
//}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.maximumZoomScale = 5.0;
        self.minimumZoomScale = 1.0;
        self.delegate = self;
        
        [self addSubview:self.zoomImageView];
    }
    return self;
}

- (UIImageView *)zoomImageView{
    if(!_zoomImageView){
        _zoomImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"apple"]];
        _zoomImageView.frame = self.bounds;
    }
    return  _zoomImageView;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return self.zoomImageView;
}

//缩放中
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    if (scrollView.isZooming || scrollView.isZoomBouncing) {
        // 延中心点缩放
        CGRect rect = CGRectApplyAffineTransform(scrollView.frame, scrollView.transform);
        CGFloat offsetX = (rect.size.width > scrollView.contentSize.width) ? ((rect.size.width - scrollView.contentSize.width) * 0.5) : 0.0;
        CGFloat offsetY = (rect.size.height > scrollView.contentSize.height) ? ((rect.size.height - scrollView.contentSize.height) * 0.5) : 0.0;
        self.zoomImageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
    }
}

@end
