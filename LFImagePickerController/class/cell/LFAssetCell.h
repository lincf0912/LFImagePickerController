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
@property (nonatomic, copy) void (^didSelectPhotoBlock)(BOOL isSelected, LFAsset *model);
/** 只能选中 */
@property (nonatomic, assign) BOOL onlySelected;
/** 不能选中 */
@property (nonatomic, assign) BOOL noSelected;

@property (nonatomic, copy) NSString *photoSelImageName;
@property (nonatomic, copy) NSString *photoDefImageName;

@end

/// 拍照视图

@interface LFAssetCameraCell : UICollectionViewCell

@property (nonatomic, copy) UIImage *posterImage;

@end
