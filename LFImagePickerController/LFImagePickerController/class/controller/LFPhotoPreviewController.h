//
//  LFPhotoPreviewController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"

@class LFAsset;
@interface LFPhotoPreviewController : LFBaseViewController

/// Return the new selected photos / 返回最新的选中图片数组
@property (nonatomic, copy) void (^backButtonClickBlock)();
@property (nonatomic, copy) void (^doneButtonClickBlock)();

/** 初始化 */
- (instancetype)initWithModels:(NSArray <LFAsset *>*)models index:(NSInteger)index;
/** 图片预览模式 没有asset对象 只有previewImage */
- (instancetype)initWithPhotos:(NSArray <LFAsset *>*)photos index:(NSInteger)index;

/** 总是显示预览框 */
@property (nonatomic, assign) BOOL alwaysShowPreviewBar;

/** 3DTouch */
- (void)beginPreviewing:(UINavigationController *)navi;
- (void)endPreviewing;

@end
