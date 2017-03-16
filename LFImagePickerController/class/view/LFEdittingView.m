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

@interface LFEdittingView () <UIScrollViewDelegate, LFClippingViewDelegate, LFGridViewDelegate>

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
    clippingView.clippingDelegate = self;
    [self addSubview:clippingView];
    self.clippingView = clippingView;
    
    LFGridView *gridView = [[LFGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    /** 先隐藏剪裁网格 */
    gridView.alpha = 0.f;
    [self addSubview:gridView];
    self.gridView = gridView;
    
    self.clippingMinSize = CGSizeMake(80, 80);
    self.clippingMaxRect = CGRectInset(self.frame , 20, 50);
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
    self.clippingView.cropRect = clippingRect;
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
        self.clippingView.editRect = clippingMaxRect;
    }
}

- (void)setIsClipping:(BOOL)isClipping
{
    [self setIsClipping:isClipping animated:NO];
}
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated
{
    [self setZoomScale:1.f];
    _isClipping = isClipping;
    if (isClipping) {
        /** 显示多余部分 */
        self.clippingView.clipsToBounds = NO;
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
                } completion:^(BOOL finished) {
                    /** 剪裁多余部分 */
                    self.clippingView.clipsToBounds = YES;
                }];
            }];
        } else {
            self.gridView.alpha = 0.f;
            CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(_image.size, self.frame);
            self.clippingRect = cropRect;
            self.clippingView.clipsToBounds = YES;
        }
    }
}

/** 还原 */
- (void)reset
{
    if (_isClipping) {
        self.gridView.showMaskLayer = NO;
        [UIView animateWithDuration:0.25f animations:^{
            [self.clippingView setZoomScale:1.f];
            [self.gridView setGridRect:self.clippingRect animated:YES];
            [self.clippingView setCropRect:self.clippingRect];
        } completion:^(BOOL finished) {
            self.gridView.showMaskLayer = YES;
        }];
    }
}

#pragma mark - LFClippingViewDelegate
- (void (^)(CGRect))lf_clippingViewWillBeginZooming:(LFClippingView *)clippingView
{
    __weak typeof(self) weakSelf = self;
    void (^block)(CGRect) = ^(CGRect rect){
        [weakSelf.gridView setGridRect:rect animated:YES];
    };
    return block;
}
- (void)lf_clippingViewDidEndZooming:(LFClippingView *)clippingView
{
    self.gridView.showMaskLayer = YES;
}

- (void)lf_clippingViewWillBeginDragging:(LFClippingView *)clippingView
{
    /** 移动开始，隐藏 */
    self.gridView.showMaskLayer = NO;
}
- (void)lf_clippingViewDidEndDecelerating:(LFClippingView *)clippingView
{
    /** 移动结束，显示 */
    self.gridView.showMaskLayer = YES;
}

#pragma mark - LFGridViewDelegate
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
    [self.clippingView zoomOutToRect:gridView.gridRect];
    /** 让clippingView的动画回调后才显示showMaskLayer */
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
    } else if (self.isClipping && view == self) {
        return self.clippingView;
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
