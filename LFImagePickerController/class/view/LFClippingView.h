//
//  LFClippingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFScrollView.h"
#import "LFEdittingProtocol.h"

@protocol LFClippingViewDelegate;

@interface LFClippingView : LFScrollView <LFEdittingProtocol>

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, weak) id<LFClippingViewDelegate> clippingDelegate;

/** 是否重置中 */
@property (nonatomic, readonly) BOOL isReseting;
/** 是否可还原 */
@property (nonatomic, readonly) BOOL canReset;

/** 可编辑范围 */
@property (nonatomic, assign) CGRect editRect;
/** 剪切范围 */
@property (nonatomic, assign) CGRect cropRect;

/** 缩放 */
- (void)zoomOutToRect:(CGRect)toRect;
/** 还原 */
- (void)reset;
/** 取消 */
- (void)cancel;

@end

@protocol LFClippingViewDelegate <NSObject>

/** 同步缩放视图（调用zoomOutToRect才会触发） */
- (void (^)(CGRect))lf_clippingViewWillBeginZooming:(LFClippingView *)clippingView;
- (void)lf_clippingViewDidEndZooming:(LFClippingView *)clippingView;

/** 移动视图(包含缩放) */
- (void)lf_clippingViewWillBeginDragging:(LFClippingView *)clippingView;
- (void)lf_clippingViewDidEndDecelerating:(LFClippingView *)clippingView;

@end
