//
//  LFGridView.h
//  ClippingText
//
//  Created by LamTsanFeng on 2017/3/7.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol lf_gridViewDelegate;
@interface LFGridView : UIView

@property (nonatomic, assign) CGRect gridRect;
- (void)setGridRect:(CGRect)gridRect animated:(BOOL)animated;
/** 最小尺寸 CGSizeMake(80, 80); */
@property (nonatomic, assign) CGSize controlMinSize;
/** 最大尺寸 CGRectInset(self.bounds, 50, 50) */
@property (nonatomic, assign) CGRect controlMaxRect;

/** 显示遮罩层 */
@property (nonatomic, assign) BOOL showMaskLayer;

@property (nonatomic, weak) id<lf_gridViewDelegate> delegate;

@end

@protocol lf_gridViewDelegate <NSObject>

- (void)lf_gridViewDidBeginResizing:(LFGridView *)gridView;
- (void)lf_gridViewDidResizing:(LFGridView *)gridView;
- (void)lf_gridViewDidEndResizing:(LFGridView *)gridView;

@end
