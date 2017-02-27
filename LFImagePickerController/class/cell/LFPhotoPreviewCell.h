//
//  LFPhotoPreviewCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFAsset;
@interface LFPhotoPreviewCell : UICollectionViewCell

@property (nonatomic, strong) LFAsset *model;
@property (nonatomic, copy) void (^singleTapGestureBlock)();
@property (nonatomic, copy) void (^imageProgressUpdateBlock)(double progress);

/** 当前展示的图片 */
@property (nonatomic, readwrite) UIImage *previewImage;

- (void)recoverSubviews;

@end
