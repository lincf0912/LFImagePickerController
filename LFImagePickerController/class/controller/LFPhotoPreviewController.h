//
//  LFPhotoPreviewController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFAsset;
@interface LFPhotoPreviewController : UIViewController

@property (nonatomic, strong) NSMutableArray <LFAsset *>*models;                  ///< All photo models / 所有图片模型数组
@property (nonatomic, strong) NSMutableArray <UIImage *>*photos;                  ///< All photos  / 所有图片数组
@property (nonatomic, assign) NSInteger currentIndex;           ///< Index of the photo user click / 用户点击的图片的索引

/// Return the new selected photos / 返回最新的选中图片数组
@property (nonatomic, copy) void (^backButtonClickBlock)();
@property (nonatomic, copy) void (^doneButtonClickBlock)();
@end
