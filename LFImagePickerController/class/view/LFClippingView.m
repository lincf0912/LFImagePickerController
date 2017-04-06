//
//  LFClippingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClippingView.h"
#import "LFZoomingView.h"
#import "UIView+LFFrame.h"
#import <AVFoundation/AVFoundation.h>

#define kRound(x) (round(x*100000)/100000)

NSString *const kLFClippingViewData = @"LFClippingViewData";

NSString *const kLFClippingViewData_frame = @"LFClippingViewData_frame";
NSString *const kLFClippingViewData_zoomScale = @"LFClippingViewData_zoomScale";
NSString *const kLFClippingViewData_contentSize = @"LFClippingViewData_contentSize";
NSString *const kLFClippingViewData_contentOffset = @"LFClippingViewData_contentOffset";
NSString *const kLFClippingViewData_minimumZoomScale = @"LFClippingViewData_minimumZoomScale";
NSString *const kLFClippingViewData_maximumZoomScale = @"LFClippingViewData_maximumZoomScale";
NSString *const kLFClippingViewData_clipsToBounds = @"LFClippingViewData_clipsToBounds";

NSString *const kLFClippingViewData_reset_minimumZoomScale = @"LFClippingViewData_reset_minimumZoomScale";

NSString *const kLFClippingViewData_zoomingView = @"LFClippingViewData_zoomingView";

@interface LFClippingView () <UIScrollViewDelegate>

@property (nonatomic, weak) LFZoomingView *zoomingView;

/** 原始坐标 */
@property (nonatomic, assign) CGRect originalRect;
/** 开始的基础坐标 */
@property (nonatomic, assign) CGRect normalRect;
/** 处理完毕的基础坐标（因为可能会被父类在缩放时改变当前frame的问题，导致记录坐标不正确） */
@property (nonatomic, assign) CGRect saveRect;
/** 首次缩放后需要记录最小缩放值，否则在多次重复编辑后由于大小发生改变，导致最小缩放值不准确，还原不回实际大小 */
@property (nonatomic, assign) CGFloat reset_minimumZoomScale;

/** 记录剪裁前的数据 */
@property (nonatomic, assign) CGRect old_frame;
@property (nonatomic, assign) CGFloat old_zoomScale;
@property (nonatomic, assign) CGSize old_contentSize;
@property (nonatomic, assign) CGPoint old_contentOffset;
@property (nonatomic, assign) CGFloat old_minimumZoomScale;
@property (nonatomic, assign) CGFloat old_maximumZoomScale;
@end

@implementation LFClippingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _originalRect = frame;
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;
    self.delegate = self;
    self.minimumZoomScale = 1.0f;
    self.maximumZoomScale = 5.0f;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    
    LFZoomingView *zoomingView = [[LFZoomingView alloc] initWithFrame:self.bounds];
    __weak typeof(self) weakSelf = self;
    zoomingView.moveCenter = ^BOOL(CGRect rect) {
        /** 判断缩放后是否超出边界线 */
        CGRect newRect = [weakSelf.zoomingView convertRect:rect toView:weakSelf];
        CGRect screenRect = (CGRect){weakSelf.contentOffset, weakSelf.frame.size};
        return !CGRectIntersectsRect(screenRect, newRect);
    };
    [self addSubview:zoomingView];
    self.zoomingView = zoomingView;
    
    /** 默认编辑范围 */
    _editRect = self.bounds;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self setZoomScale:1.f];
    if (image) {        
        CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(image.size, self.originalRect);
        self.frame = cropRect;
    } else {
        self.frame = _originalRect;
    }
    self.normalRect = self.frame;
    self.saveRect = self.frame;
    [self.zoomingView setImage:image];
    
}

- (void)setCropRect:(CGRect)cropRect
{
    /** 记录当前数据 */
    self.old_frame = self.frame;
    self.old_zoomScale = self.zoomScale;
    self.old_contentSize = self.contentSize;
    self.old_contentOffset = self.contentOffset;
    self.old_minimumZoomScale = self.minimumZoomScale;
    self.old_maximumZoomScale = self.maximumZoomScale;
    
    _cropRect = cropRect;
    
    /** 当前UI位置未改变时，获取contentOffset与contentSize */
    /** 计算未改变前当前视图在contentSize的位置比例 */
    CGPoint contentOffset = self.contentOffset;
    CGFloat scaleX = MAX(contentOffset.x/(self.contentSize.width-self.width), 0);
    CGFloat scaleY = MAX(contentOffset.y/(self.contentSize.height-self.height), 0);
    /** 获取contentOffset必须在设置contentSize之前，否则重置frame 或 contentSize后contentOffset会发送变化 */
    
    CGRect oldFrame = self.frame;
    self.frame = cropRect;
    self.saveRect = self.frame;
    
    CGFloat scale = self.zoomScale;
    /** 视图位移 */
    CGFloat scaleZX = CGRectGetWidth(cropRect)/(CGRectGetWidth(oldFrame)/scale);
    CGFloat scaleZY = CGRectGetHeight(cropRect)/(CGRectGetHeight(oldFrame)/scale);
    
    if (scaleZX < self.minimumZoomScale && scaleZY < self.minimumZoomScale) {
        CGFloat minimumZoomScale = self.minimumZoomScale;
        self.minimumZoomScale = MAX(scaleZX, scaleZY);
        scale = self.zoomScale - (minimumZoomScale - self.minimumZoomScale);
    } else {
        self.maximumZoomScale = (MIN(scaleZX, scaleZY) > 5 ? MIN(scaleZX, scaleZY) : 5);
        scale = kRound(MIN(scaleZX, scaleZY));
        if (scale == 1) {
            self.minimumZoomScale = 1.f;
        }
    }
    [self setZoomScale:scale];
    
    /** 记录首次最小缩放值 */
    if (self.reset_minimumZoomScale == 0) {
        self.reset_minimumZoomScale = self.minimumZoomScale;
    }
    
    /** 重设contentSize */
    self.contentSize = self.zoomingView.size;
    /** 获取当前contentOffset的最大限度，根据之前的位置比例计算实际偏移坐标 */
    contentOffset.x = isnan(scaleX) ? contentOffset.x : (scaleX > 0 ? (self.contentSize.width-self.width) * scaleX : contentOffset.x);
    contentOffset.y = isnan(scaleY) ? contentOffset.y : (scaleY > 0 ? (self.contentSize.height-self.height) * scaleY : contentOffset.y);
    self.contentOffset = CGPointMake(MIN(MAX(contentOffset.x, 0),self.zoomingView.width-self.width), MIN(MAX(contentOffset.y, 0),self.zoomingView.height-self.height));
}

/** 取消 */
- (void)cancel
{
    if (!CGRectEqualToRect(self.old_frame, CGRectZero)) {        
        self.frame = self.old_frame;
        self.saveRect = self.frame;
        self.minimumZoomScale = self.old_minimumZoomScale;
        self.maximumZoomScale = self.old_maximumZoomScale;
        self.zoomScale = self.old_zoomScale;
        self.contentSize = self.old_contentSize;
        self.contentOffset = self.old_contentOffset;
    }
}

- (void)reset
{
    if (!_isReseting) {        
        _isReseting = YES;
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.minimumZoomScale = self.reset_minimumZoomScale;
                             [self setZoomScale:self.minimumZoomScale];
                             self.frame = (CGRect){CGPointZero, self.zoomingView.size};
                             self.saveRect = self.frame;
                             self.center = self.superview.center;
                             /** 重设contentSize */
                             self.contentSize = self.zoomingView.size;
                             /** 重置contentOffset */
                             self.contentOffset = CGPointZero;
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewWillBeginZooming:)]) {
                                 void (^block)() = [self.clippingDelegate lf_clippingViewWillBeginZooming:self];
                                 if (block) block(self.frame);
                             }
                         } completion:^(BOOL finished) {
                             if ([self.clippingDelegate respondsToSelector:@selector(lf_clippingViewDidEndZooming:)]) {
                                 [self.clippingDelegate lf_clippingViewDidEndZooming:self];
                             }
                             _isReseting = NO;
                         }];
    }
}

- (BOOL)canReset
{
    CGRect trueFrame = CGRectMake((CGRectGetWidth(self.superview.frame)-CGRectGetWidth(self.zoomingView.frame))/2
                                  , (CGRectGetHeight(self.superview.frame)-CGRectGetHeight(self.zoomingView.frame))/2
                                  , CGRectGetWidth(self.zoomingView.frame)
                                  , CGRectGetHeight(self.zoomingView.frame));
    return !(self.zoomScale == self.minimumZoomScale && CGRectEqualToRect(trueFrame, self.frame));
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
    if (CGRectEqualToRect(self.frame, rect) || (self.zoomScale == self.maximumZoomScale && kRound(scale) > 1.f)) {
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
    scaledWidth = MIN(scaledWidth, CGRectGetWidth(self.zoomingView.frame) * (zoomScale / self.minimumZoomScale));
    scaledHeight = MIN(scaledHeight, CGRectGetHeight(self.zoomingView.frame) * (zoomScale / self.minimumZoomScale));
    
    /** 计算实际显示坐标 */
    CGRect cropRect = CGRectMake((CGRectGetWidth(self.superview.bounds) - scaledWidth) / 2,
                                 (CGRectGetHeight(self.superview.bounds) - scaledHeight) / 2,
                                 scaledWidth,
                                 scaledHeight);
    
    /** 获取相对坐标 */
    CGRect zoomRect = [self.superview convertRect:rect toView:self.zoomingView];
    
    
    /** 计算偏移值 */
    __block CGPoint contentOffset = self.contentOffset;
    if (![self verifyRect:cropRect]) { /** 实际位置与当前位置一致不做位移处理 */
        contentOffset.x = zoomRect.origin.x * zoomScale;
        contentOffset.y = zoomRect.origin.y * zoomScale;
    }
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.frame = cropRect;
                         self.saveRect = self.frame;
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
                             self.saveRect = self.frame;
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

#pragma mark - 验证当前大小是否被修改
- (BOOL)verifyRect:(CGRect)r_rect
{
    /** 计算缩放率 */
    CGRect rect = CGRectApplyAffineTransform(r_rect, self.transform);
    /** 模糊匹配 */
    BOOL isEqual = CGRectEqualToRect(rect, self.frame);
    
    if (isEqual == NO) {
        /** 精准验证 */
        BOOL x = kRound(CGRectGetMinX(rect)) == kRound(CGRectGetMinX(self.frame));
        BOOL y = kRound(CGRectGetMinY(rect)) == kRound(CGRectGetMinY(self.frame));
        BOOL w = kRound(CGRectGetWidth(rect)) == kRound(CGRectGetWidth(self.frame));
        BOOL h = kRound(CGRectGetHeight(rect)) == kRound(CGRectGetHeight(self.frame));
        isEqual = x && y && w && h;
    }
    return isEqual;
}

#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{    
//    if ([[self.zoomingView subviews] containsObject:view]) {
//        if (event.allTouches.count == 1) { /** 1个手指 */
//            return YES;
//        } else if (event.allTouches.count == 2) { /** 2个手指 */
//            return NO;
//        }
//    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
//    if ([[self.zoomingView subviews] containsObject:view]) {
//        return NO;
//    } else if (![[self subviews] containsObject:view]) { /** 非自身子视图 */
//        return NO;
//    }
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

#pragma mark - LFEdittingProtocol

- (void)setEditDelegate:(id<LFPhotoEditDelegate>)editDelegate
{
    self.zoomingView.editDelegate = editDelegate;
}

- (id<LFPhotoEditDelegate>)editDelegate
{
    return self.zoomingView.editDelegate;
}

/** 禁用其他功能 */
- (void)photoEditEnable:(BOOL)enable
{
    [self.zoomingView photoEditEnable:enable];
}

#pragma mark - 数据
- (NSDictionary *)photoEditData
{
    NSMutableDictionary *data = [@{} mutableCopy];
    /** 计算缩放率 */
    CGRect rect = CGRectApplyAffineTransform(self.normalRect, self.transform);
    
    if (kRound(self.zoomScale) != 1 || /** 被缩放了 */
        !(kRound(CGRectGetWidth(rect)) == kRound(CGRectGetWidth(self.frame))
          && kRound(CGRectGetHeight(rect)) == kRound(CGRectGetHeight(self.frame)))) { /** 被剪裁了 */
//        CGRect trueFrame = CGRectApplyAffineTransform(self.frame, CGAffineTransformInvert(self.transform));
        NSDictionary *myData = @{kLFClippingViewData_frame:[NSValue valueWithCGRect:self.saveRect]
                                 , kLFClippingViewData_zoomScale:@(self.zoomScale)
                                 , kLFClippingViewData_contentSize:[NSValue valueWithCGSize:self.contentSize]
                                 , kLFClippingViewData_contentOffset:[NSValue valueWithCGPoint:self.contentOffset]
                                 , kLFClippingViewData_minimumZoomScale:@(self.minimumZoomScale)
                                 , kLFClippingViewData_maximumZoomScale:@(self.maximumZoomScale)
                                 , kLFClippingViewData_clipsToBounds:@(self.clipsToBounds)
                                 , kLFClippingViewData_reset_minimumZoomScale:@(self.reset_minimumZoomScale)};
        [data setObject:myData forKey:kLFClippingViewData];
    }
    
    NSDictionary *zoomingViewData = self.zoomingView.photoEditData;
    if (zoomingViewData) [data setObject:zoomingViewData forKey:kLFClippingViewData_zoomingView];
    
    if (data.count) {
        return data;
    }
    return nil;
}

- (void)setPhotoEditData:(NSDictionary *)photoEditData
{
    NSDictionary *myData = photoEditData[kLFClippingViewData];
    if (myData) {
        self.frame = [myData[kLFClippingViewData_frame] CGRectValue];
        self.minimumZoomScale = [myData[kLFClippingViewData_minimumZoomScale] floatValue];
        self.maximumZoomScale = [myData[kLFClippingViewData_maximumZoomScale] floatValue];
        self.zoomScale = [myData[kLFClippingViewData_zoomScale] floatValue];
        self.contentSize = [myData[kLFClippingViewData_contentSize] CGSizeValue];
        self.contentOffset = [myData[kLFClippingViewData_contentOffset] CGPointValue];
        self.clipsToBounds = [myData[kLFClippingViewData_clipsToBounds] boolValue];
        self.reset_minimumZoomScale = [myData[kLFClippingViewData_reset_minimumZoomScale] floatValue];
    }
    
    self.zoomingView.photoEditData = photoEditData[kLFClippingViewData_zoomingView];
}

#pragma mark - 绘画功能
/** 启用绘画功能 */
- (void)setDrawEnable:(BOOL)drawEnable
{
    self.zoomingView.drawEnable = drawEnable;
}
- (BOOL)drawEnable
{
    return self.zoomingView.drawEnable;
}

- (BOOL)drawCanUndo
{
    return [self.zoomingView drawCanUndo];
}
- (void)drawUndo
{
    [self.zoomingView drawUndo];
}
/** 设置绘画颜色 */
- (void)setDrawColor:(UIColor *)color
{
    [self.zoomingView setDrawColor:color];
}

#pragma mark - 贴图功能
/** 取消激活贴图 */
- (void)stickerDeactivated
{
    [self.zoomingView stickerDeactivated];
}
- (void)activeSelectStickerView
{
    [self.zoomingView activeSelectStickerView];
}
/** 删除选中贴图 */
- (void)removeSelectStickerView
{
    [self.zoomingView removeSelectStickerView];
}
/** 获取选中贴图的内容 */
- (LFText *)getSelectStickerText
{
    return [self.zoomingView getSelectStickerText];
}
/** 更改选中贴图内容 */
- (void)changeSelectStickerText:(LFText *)text
{
    [self.zoomingView changeSelectStickerText:text];
}

/** 创建贴图 */
- (void)createStickerImage:(UIImage *)image
{
    [self.zoomingView createStickerImage:image];
}

#pragma mark - 文字功能
/** 创建文字 */
- (void)createStickerText:(LFText *)text
{
    [self.zoomingView createStickerText:text];
}

#pragma mark - 模糊功能
/** 启用模糊功能 */
- (void)setSplashEnable:(BOOL)splashEnable
{
    self.zoomingView.splashEnable = splashEnable;
}
- (BOOL)splashEnable
{
    return self.zoomingView.splashEnable;
}
/** 是否可撤销 */
- (BOOL)splashCanUndo
{
    return [self.zoomingView splashCanUndo];
}
/** 撤销模糊 */
- (void)splashUndo
{
    [self.zoomingView splashUndo];
}

- (void)setSplashState:(BOOL)splashState
{
    self.zoomingView.splashState = splashState;
}

- (BOOL)splashState
{
    return self.zoomingView.splashState;
}

@end
