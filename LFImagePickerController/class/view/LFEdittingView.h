//
//  LFEdittingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFScrollView.h"
#import "LFEdittingProtocol.h"

@protocol LFEdittingViewDelegate;

@interface LFEdittingView : LFScrollView <LFEdittingProtocol>

@property (nonatomic, strong) UIImage *image;

/** 代理 */
@property (nonatomic, weak) id<LFEdittingViewDelegate> clippingDelegate;

/** 最小尺寸 CGSizeMake(80, 80) */
@property (nonatomic, assign) CGSize clippingMinSize;
/** 最大尺寸 CGRectInset(self.frame , 20, 50) */
@property (nonatomic, assign) CGRect clippingMaxRect;

@property (nonatomic, assign) BOOL isClipping;
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated;

/** 取消剪裁 */
- (void)cancelClipping:(BOOL)animated;
/** 还原 isClipping=YES 的情况有效 */
- (void)reset;
- (BOOL)canReset;
@end


@protocol LFEdittingViewDelegate <NSObject>
/** 剪裁发生变化后 */
- (void)lf_edittingViewDidEndZooming:(LFEdittingView *)edittingView;
/** 剪裁目标移动后 */
- (void)lf_edittingViewEndDecelerating:(LFEdittingView *)edittingView;
@end
