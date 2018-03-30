//
//  LFAssetCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class LFAsset;

/// 宫格图片视图

@interface LFAssetCell : UICollectionViewCell

@property (nonatomic, strong) LFAsset *model;
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL isSelected, LFAsset *model, LFAssetCell *weakCell);
/** 只能选中 */
@property (nonatomic, assign) BOOL onlySelected;
/** 只能点击；但优先级低于只能选中onlySelected */
@property (nonatomic, assign) BOOL onlyClick;
/** 不能选中 */
@property (nonatomic, assign) BOOL noSelected;

@property (nonatomic, copy) NSString *photoSelImageName;
@property (nonatomic, copy) NSString *photoDefImageName;

@property (nonatomic, assign) BOOL displayGif;
@property (nonatomic, assign) BOOL displayLivePhoto;
@property (nonatomic, assign) BOOL displayPhotoName;

/** 设置选中 */
- (void)selectPhoto:(BOOL)isSelected index:(NSUInteger)index animated:(BOOL)animated;

@end

/// 拍照视图

@interface LFAssetCameraCell : UICollectionViewCell

@property (nonatomic, copy) UIImage *posterImage;

@end
