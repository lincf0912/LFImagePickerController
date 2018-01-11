//
//  LFPhotoEditManager.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#ifdef LF_MEDIAEDIT

@class LFPhotoEdit, LFAsset, LFResultImage;
@interface LFPhotoEditManager : NSObject

+ (instancetype)manager NS_SWIFT_NAME(default());
+ (void)free;

/** 设置编辑对象 */
- (void)setPhotoEdit:(LFPhotoEdit *)obj forAsset:(LFAsset *)asset;
/** 获取编辑对象 */
- (LFPhotoEdit *)photoEditForAsset:(LFAsset *)asset;


/**
 *  通过asset解析缩略图、标清图/原图、图片数据字典
 *
 *  @param asset      LFAsset
 *  @param isOriginal 是否原图
 *  @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(LFAsset *)asset
               isOriginal:(BOOL)isOriginal
               completion:(void (^)(LFResultImage *resultImage))completion;


/**
 通过asset解析缩略图、标清图/原图、图片数据字典

 @param asset LFAsset
 @param isOriginal 是否原图
 @param compressSize 非原图的压缩大小
 @param thumbnailCompressSize 缩略图压缩大小
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(LFAsset *)asset
               isOriginal:(BOOL)isOriginal
             compressSize:(CGFloat)compressSize
    thumbnailCompressSize:(CGFloat)thumbnailCompressSize
               completion:(void (^)(LFResultImage *resultImage))completion;
@end

#endif
