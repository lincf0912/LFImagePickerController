//
//  LFPhotoPickerController+preview.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2018/7/17.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPickerController.h"
@class LFAsset;

@interface LFPhotoPickerController ()

/** 图片预览模式 */
- (instancetype)initWithPhotos:(NSArray <LFAsset *>*)photos completeBlock:(void (^)(void))completeBlock;

@end
