//
//  LFPhotoPreviewCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFPhotoPreviewCellDelegate;

@class LFAsset;
@interface LFPhotoPreviewCell : UICollectionViewCell

@property (nonatomic, strong) LFAsset *model;
@property (nonatomic, weak) id<LFPhotoPreviewCellDelegate> delegate;

/** 当前展示的图片 */
@property (nonatomic, readonly) UIImage *previewImage;

// 即将显示
- (void)willDisplayCell;
// 正式显示
- (void)didDisplayCell;
// 即将消失
- (void)willEndDisplayCell;
// 正式消失
- (void)didEndDisplayCell;


/** 子类重写 */
/** 创建显示视图 */
- (UIView *)subViewInitDisplayView;
/** 重置视图 */
- (void)subViewReset;
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler;
@end

@protocol LFPhotoPreviewCellDelegate <NSObject>
@optional
- (void)lf_photoPreviewCellSingleTapHandler:(LFPhotoPreviewCell *)cell;
@end
