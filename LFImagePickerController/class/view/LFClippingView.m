//
//  LFClippingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClippingView.h"
#import "LFGridView.h"
#import "LFZoomView.h"

#import <AVFoundation/AVFoundation.h>

const CGFloat minClipSize = 50.f;

@interface LFClippingView () <lf_zoomViewDelegate, lf_gridViewDelegate>

@property (nonatomic, weak) LFGridView *gridView;
@property (nonatomic, weak) LFZoomView *zoomView;

/** 剪裁尺寸, CGRectInset(self.bounds, 50, 50) */
@property (nonatomic, assign) CGRect clippingRect;
@end

@implementation LFClippingView

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
    self.backgroundColor = [UIColor blackColor];
    
    LFZoomView *zoomView = [[LFZoomView alloc] initWithFrame:self.bounds];
    zoomView.delegate = self;
    [self addSubview:zoomView];
    self.zoomView = zoomView;
    
    LFGridView *gridView = [[LFGridView alloc] initWithFrame:self.bounds];
    gridView.delegate = self;
    [self addSubview:gridView];
    self.gridView = gridView;
    
    self.clippingRect = CGRectInset(self.bounds, minClipSize, minClipSize);
    self.clippingMinSize = CGSizeMake(80, 80);
    self.clippingMaxRect = CGRectInset(self.bounds, 30, 50);
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    self.zoomView.image = image;
    /** 计算图片剪裁尺寸 */
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.clippingMaxRect);
    self.clippingRect = cropRect;
    CGFloat minSize = MIN(cropRect.size.width, cropRect.size.height);
    if (minSize < MIN(self.clippingMinSize.width, self.clippingMinSize.height)) {
        self.clippingMinSize = CGSizeMake(minSize, minSize);
    }
}

- (void)setClippingRect:(CGRect)clippingRect
{
    _clippingRect = clippingRect;
    self.gridView.gridRect = clippingRect;
    self.zoomView.cropRect = clippingRect;
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
        self.zoomView.editRect = clippingMaxRect;
    }
}

/** 还原 */
- (void)reset
{
    self.clippingRect = _clippingRect;
}



- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (self == view) {
        return nil;
    }
    return view;
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
    [self.zoomView zoomInToRect:gridView.gridRect];
}
- (void)lf_gridViewDidEndResizing:(LFGridView *)gridView
{
    [self.zoomView zoomOutToRect:gridView.gridRect];
    /** 让zoomView的动画回调后才显示showMaskLayer */
//    self.gridView.showMaskLayer = YES;
}

@end
