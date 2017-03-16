//
//  LFClippingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClippingView.h"
#import "UIView+LFFrame.h"
#import <AVFoundation/AVFoundation.h>

@interface LFClippingView () <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *zoomingView;
@property (nonatomic, weak) UIImageView *imageView;

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
    self.backgroundColor = [UIColor blueColor];
    self.clipsToBounds = NO;
    self.delegate = self;
    self.minimumZoomScale = 1.0f;
    self.maximumZoomScale = 5.0f;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    
    UIView *zoomingView = [[UIView alloc] initWithFrame:self.bounds];
    zoomingView.backgroundColor = [UIColor clearColor];
    zoomingView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:zoomingView];
    self.zoomingView = zoomingView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.zoomingView.bounds];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.zoomingView addSubview:imageView];
    self.imageView = imageView;
    
    /** 默认编辑范围 */
    self.editRect = self.bounds;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.imageView setImage:image];
    [self setZoomScale:1.f];
}

- (void)setCropRect:(CGRect)cropRect
{
    /** 当前UI位置未改变时，获取contentOffset与contentSize */
    /** 计算未改变前当前视图在contentSize的位置比例 */
    CGFloat scaleX = MAX(self.contentOffset.x/(self.contentSize.width-self.width), 0);
    CGFloat scaleY = MAX(self.contentOffset.y/(self.contentSize.height-self.height), 0);
    /** 获取contentOffset必须在设置contentSize之前，否则重置frame 或 contentSize后contentOffset会发送变化 */
    
    _cropRect = cropRect;
    CGRect oldFrame = self.frame;
    self.frame = cropRect;
    
    /** 视图位移 */
    CGSize size = CGSizeMake(CGRectGetWidth(oldFrame)-CGRectGetWidth(self.frame), CGRectGetHeight(oldFrame)-CGRectGetHeight(self.frame));
    self.zoomingView.width -= size.width*self.zoomScale;
    self.zoomingView.height -= size.height*self.zoomScale;
    self.imageView.width -= size.width;
    self.imageView.height -= size.height;
    
//    CGPoint offset = CGPointMake(CGRectGetMinX(oldFrame)-CGRectGetMinX(self.frame), CGRectGetMinY(oldFrame)-CGRectGetMinY(self.frame));
    /** 重设contentSize */
    self.contentSize = self.zoomingView.size;
    /** 获取改变contentSize后的contentOffset */
    CGPoint contentOffset = self.contentOffset;
    /** 获取当前contentOffset的最大限度，根据之前的位置比例计算实际偏移坐标 */
    contentOffset.x = scaleX > 0 ? (self.contentSize.width-self.width) * scaleX : contentOffset.x;
    contentOffset.y = scaleY > 0 ? (self.contentSize.height-self.height) * scaleY : contentOffset.y;
    self.contentOffset = CGPointMake(MIN(MAX(contentOffset.x, 0),self.zoomingView.width-self.width), MIN(MAX(contentOffset.y, 0),self.zoomingView.height-self.height));
}

- (void)doOffset:(CGRect)oldFrame view:(UIView *)view
{
    CGPoint offset = CGPointMake(CGRectGetMinX(oldFrame)-CGRectGetMinX(self.frame), CGRectGetMinY(oldFrame)-CGRectGetMinY(self.frame));
    CGSize size = CGSizeMake(CGRectGetWidth(oldFrame)-CGRectGetWidth(self.frame), CGRectGetHeight(oldFrame)-CGRectGetHeight(self.frame));
    CGRect newFrame = view.frame;
    newFrame.origin.x -= offset.x;
    newFrame.origin.y -= offset.y;
    newFrame.size.width -= size.width;
    newFrame.size.height -= size.height;
    view.frame = newFrame;
}

- (void)reset
{
    [self setZoomScale:1.f];
    self.cropRect = self.cropRect;
}

- (CGRect)cappedCropRectInImageRectWithCropRect:(CGRect)cropRect
{
    CGRect rect = [self.superview convertRect:cropRect toView:self];
    if (CGRectGetMinX(rect) < CGRectGetMinX(self.zoomingView.frame)) {
        cropRect.origin.x = CGRectGetMinX([self convertRect:self.zoomingView.frame toView:self.superview]);
        cropRect.size.width = CGRectGetMaxX(rect);
    }
    if (CGRectGetMinY(rect) < CGRectGetMinY(self.zoomingView.frame)) {
        cropRect.origin.y = CGRectGetMinY([self convertRect:self.zoomingView.frame toView:self.superview]);
        cropRect.size.height = CGRectGetMaxY(rect);
    }
    if (CGRectGetMaxX(rect) > CGRectGetMaxX(self.zoomingView.frame)) {
        cropRect.size.width = CGRectGetMaxX([self convertRect:self.zoomingView.frame toView:self.superview]) - CGRectGetMinX(cropRect);
    }
    if (CGRectGetMaxY(rect) > CGRectGetMaxY(self.zoomingView.frame)) {
        cropRect.size.height = CGRectGetMaxY([self convertRect:self.zoomingView.frame toView:self.superview]) - CGRectGetMinY(cropRect);
    }
    
    return cropRect;
}

#pragma mark 缩小到指定坐标
- (void)zoomOutToRect:(CGRect)toRect
{
    CGRect rect = [self cappedCropRectInImageRectWithCropRect:toRect];
    
    CGFloat width = CGRectGetWidth(rect);
    CGFloat height = CGRectGetHeight(rect);
    
    CGFloat scale = MIN(CGRectGetWidth(self.editRect) / width, CGRectGetHeight(self.editRect) / height);
    
    /** 指定位置=当前显示位置 或者 当前缩放已达到最大，并且仍然发送缩放的情况； 免去以下计算，以当前显示大小为准 */
    if (CGRectEqualToRect(self.frame, rect) || (self.zoomScale == self.maximumZoomScale && roundf(scale*10)/10 > 1.f)) {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                                 void (^block)() = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                                 [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                             }
                         }];
        return;
    }
    
    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    /** 计算缩放比例 */
    CGFloat zoomScale = MIN(self.zoomScale * scale, self.maximumZoomScale);
    /** 特殊图片计算 比例100:1 或 1:100 的情况 */
    scaledWidth = MIN(scaledWidth, CGRectGetWidth(self.zoomingView.frame) * zoomScale);
    scaledHeight = MIN(scaledHeight, CGRectGetHeight(self.zoomingView.frame) * zoomScale);
    
    /** 计算实际显示坐标 */
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.superview.bounds) - scaledWidth) / 2,
                                 (CGRectGetHeight(self.superview.bounds) - scaledHeight) / 2,
                                 scaledWidth,
                                 scaledHeight);
    
    /** 获取相对坐标 */
    CGRect zoomRect = [self.superview convertRect:rect toView:self.zoomingView];
    
    
    /** 计算偏移值 */
    __block CGPoint contentOffset = self.contentOffset;
    if (ceil(cropRect.origin.x) != ceil(self.frame.origin.x)
        ||ceil(cropRect.origin.y) != ceil(self.frame.origin.y)
        ||ceil(cropRect.size.width) != ceil(self.frame.size.width)
        ||ceil(cropRect.size.height) != ceil(self.frame.size.height)) { /** 实际位置与当前位置一致不做位移处理 */
        contentOffset.x = zoomRect.origin.x * zoomScale;
        contentOffset.y = zoomRect.origin.y * zoomScale;
    }
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = cropRect;
                         [self setZoomScale:zoomScale];
                         /** 超出最大限度Y值，调整到临界值 */
                         if (self.contentSize.height-contentOffset.y < CGRectGetHeight(cropRect)) {
                             contentOffset.y = self.contentSize.height-CGRectGetHeight(cropRect);
                         }
                         /** 超出最大限度X值，调整到临界值 */
                         if (self.contentSize.width-contentOffset.x < CGRectGetWidth(cropRect)) {
                             contentOffset.x = self.contentSize.width-CGRectGetWidth(cropRect);
                         }
                         [self setContentOffset:contentOffset];
                         
                         if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                             void (^block)() = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                             if (block) block(self.frame);
                         }
                     } completion:^(BOOL finished) {
                         if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                             [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                         }
                     }];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginDragging:)]) {
        [self.clippingDelegate lf_clippingViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
            [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
        [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.zoomingView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view
{
    if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginDragging:)]) {
        [self.clippingDelegate lf_clippingViewWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale
{
    /** 手动缩放后 计算是否最小值小于当前选择框范围内 */
    if (CGRectGetWidth(self.zoomingView.frame) < CGRectGetWidth(self.frame) || CGRectGetHeight(self.zoomingView.frame) < CGRectGetHeight(self.frame)) {
        CGRect rect = self.frame;
        rect.size.width = MIN(CGRectGetWidth(self.zoomingView.frame), CGRectGetWidth(self.frame));
        rect.size.height = MIN(CGRectGetHeight(self.zoomingView.frame), CGRectGetHeight(self.frame));
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.frame = rect;
                             self.center = self.superview.center;
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                                 void (^block)() = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
                                 [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
                             }
                         }];
    } else {
        if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndDecelerating:)]) {
            [self.clippingDelegate lf_clippingViewDidEndDecelerating:self];
        }
    }
}

#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{    
    
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
   
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.zoomingView) { /** 不触发下一层UI响应 */
        return self;
    }
    return view;
}

@end
