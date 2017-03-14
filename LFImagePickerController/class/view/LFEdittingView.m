//
//  LFEdittingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFEdittingView.h"
#import "LFGridView.h"
#import "LFZoomView.h"
#import "LFClippingView.h"

#import "UIView+LFFrame.h"

#import <AVFoundation/AVFoundation.h>

@interface LFEdittingView () <UIScrollViewDelegate, lf_zoomViewDelegate, lf_gridViewDelegate>

@property (nonatomic, weak) LFClippingView *clippingView;
@property (nonatomic, weak) LFGridView *gridView;

/** 剪裁尺寸, CGRectInset(self.bounds, 30, 50) */
@property (nonatomic, assign) CGRect clippingRect;
@end

@implementation LFEdittingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor redColor];
    self.delegate = self;
    self.scrollsToTop = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    /** 缩放 */
    self.bouncesZoom = YES;
    self.maximumZoomScale = 2.5;
    self.minimumZoomScale = 1.0;
    
    LFClippingView *clippingView = [[LFClippingView alloc] initWithFrame:self.bounds];
    
    [self addSubview:clippingView];
    self.clippingView = clippingView;
    
    LFGridView *gridView = [[LFGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    /** 先隐藏剪裁网格 */
    gridView.alpha = 0.f;
    [self addSubview:gridView];
    self.gridView = gridView;
    
    self.clippingMinSize = CGSizeMake(80, 80);
    self.clippingMaxRect = self.bounds;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.clippingView.image = image;
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.frame);
    self.clippingRect = cropRect;
}

- (void)setClippingRect:(CGRect)clippingRect
{
    _clippingRect = clippingRect;
    self.gridView.gridRect = clippingRect;
    self.clippingView.frame = clippingRect;
}

- (void)setClippingMinSize:(CGSize)clippingMinSize
{
    if (CGSizeEqualToSize(CGSizeZero, _clippingMinSize) || (clippingMinSize.width < CGRectGetWidth(_clippingMaxRect) && clippingMinSize.height < CGRectGetHeight(_clippingMaxRect))) {
        _clippingMinSize = clippingMinSize;
        self.gridView.controlMinSize = clippingMinSize;
    }
}

- (void)setClippingMaxRect:(CGRect)clippingMaxRect
{
    if (CGRectEqualToRect(CGRectZero, _clippingMaxRect) || (CGRectGetWidth(clippingMaxRect) > _clippingMinSize.width && CGRectGetHeight(clippingMaxRect) > _clippingMinSize.height)) {
        _clippingMaxRect = clippingMaxRect;
        self.gridView.controlMaxRect = clippingMaxRect;
    }
}

- (void)setIsClipping:(BOOL)isClipping
{
    [self setIsClipping:isClipping animated:NO];
}
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated
{
    _isClipping = isClipping;
    if (isClipping) {
        /** 动画切换 */
        if (animated) {
            [UIView animateWithDuration:0.25f animations:^{
                CGRect rect = CGRectInset(self.frame , 20, 50);
                self.clippingRect = AVMakeRectWithAspectRatioInsideRect(_image.size, rect);
            }];
            [UIView animateWithDuration:0.25f delay:0.1f options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.gridView.alpha = 1.f;
            } completion:nil];
        } else {
            CGRect rect = CGRectInset(self.frame , 20, 50);
            self.clippingRect = AVMakeRectWithAspectRatioInsideRect(_image.size, rect);
            self.gridView.alpha = 1.f;
        }
    } else {
        if (animated) {
            [UIView animateWithDuration:0.1f animations:^{
                self.gridView.alpha = 0.f;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25f animations:^{
                    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(_image.size, self.frame);
                    self.clippingRect = cropRect;
                }];
            }];
        } else {
            self.gridView.alpha = 0.f;
            CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(_image.size, self.frame);
            self.clippingRect = cropRect;
        }
    }
}

/** 还原 */
- (void)reset
{
    self.clippingRect = _clippingRect;
}

#pragma mark - lf_zoomViewDelegate

- (void (^)(CGRect))lf_zoomViewWillBeginZooming:(LFZoomView *)zoomView
{
    __weak typeof(self) weakSelf = self;
    void (^block)(CGRect) = ^(CGRect rect){
        [weakSelf.gridView setGridRect:rect animated:YES];
    };
    return block;
}

- (void)lf_zoomViewDidEndZooming:(LFZoomView *)zoomView
{
    self.gridView.showMaskLayer = YES;
}

- (void)lf_zoomViewWillBeginDragging:(LFZoomView *)zoomView
{
    self.gridView.showMaskLayer = NO;
}
- (void)lf_zoomViewDidEndDecelerating:(LFZoomView *)zoomView
{
    self.gridView.showMaskLayer = YES;
}

#pragma mark - lf_gridViewDelegate

- (void)lf_gridViewDidBeginResizing:(LFGridView *)gridView
{
    gridView.showMaskLayer = NO;
}
- (void)lf_gridViewDidResizing:(LFGridView *)gridView
{
//    [self.zoomView zoomInToRect:gridView.gridRect];
}
- (void)lf_gridViewDidEndResizing:(LFGridView *)gridView
{
//    [self.zoomView zoomOutToRect:gridView.gridRect];
    /** 让zoomView的动画回调后才显示showMaskLayer */
    //    self.gridView.showMaskLayer = YES;
}

#pragma mark - UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.clippingView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshImageZoomViewCenter];
}


#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    
    
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (!self.isClipping && [view isKindOfClass:[LFClippingView class]]) { /** 非编辑状态，改变触发响应最顶层的scrollView */
        return self;
    }
    return view;
}

#pragma mark - Private
- (void)refreshImageZoomViewCenter {
    CGFloat offsetX = (self.width > self.contentSize.width) ? ((self.width - self.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (self.height > self.contentSize.height) ? ((self.height - self.contentSize.height) * 0.5) : 0.0;
    self.clippingView.center = CGPointMake(self.contentSize.width * 0.5 + offsetX, self.contentSize.height * 0.5 + offsetY);
}

@end
