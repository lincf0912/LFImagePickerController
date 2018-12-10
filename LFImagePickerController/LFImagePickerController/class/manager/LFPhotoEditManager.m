//
//  LFPhotoEditManager.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFImagePickerHeader.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LFAsset.h"
#import "UIImage+LF_ImageCompress.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_Format.h"
#import "LFResultObject_property.h"
#import "LFAssetManager.h"
#import "LFPhotoEdit.h"


@interface LFPhotoEditManager ()

@property (nonatomic, strong) NSMutableDictionary *photoEditDict;
@end

@implementation LFPhotoEditManager

static LFPhotoEditManager *manager;
+ (instancetype)manager {
    if (manager == nil) {
        manager = [[self alloc] init];
        manager.photoEditDict = [@{} mutableCopy];
    }
    return manager;
}

+ (void)free
{
    [manager.photoEditDict removeAllObjects];
    manager = nil;
}

- (void)setPhotoEdit:(LFPhotoEdit *)obj forAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    if (asset.asset) {
        if (asset.name.length) {
            if (obj) {
                [weakSelf.photoEditDict setObject:obj forKey:asset.name];
            } else {
                [weakSelf.photoEditDict removeObjectForKey:asset.name];
            }
        } else {
            [[LFAssetManager manager] requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    if (obj) {
                        [weakSelf.photoEditDict setObject:obj forKey:name];
                    } else {
                        [weakSelf.photoEditDict removeObjectForKey:name];
                    }
                }
            }];
        }
    }
}

- (LFPhotoEdit *)photoEditForAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    __block LFPhotoEdit *photoEdit = nil;
    if (asset.asset) {
        if (asset.name.length) {
            photoEdit = [weakSelf.photoEditDict objectForKey:asset.name];
        } else {
            [[LFAssetManager manager] requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    photoEdit = [weakSelf.photoEditDict objectForKey:name];
                }
            }];
        }
    }
    return photoEdit;
}

/**
 通过asset解析缩略图、标清图/原图、图片数据字典
 
 @param asset LFAsset
 @param isOriginal 是否原图
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(LFAsset *)asset
               isOriginal:(BOOL)isOriginal
               completion:(void (^)(LFResultImage *resultImage))completion
{
    [self getPhotoWithAsset:asset isOriginal:isOriginal compressSize:kCompressSize thumbnailCompressSize:kThumbnailCompressSize completion:completion];
}

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
               completion:(void (^)(LFResultImage *resultImage))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        CGFloat thumbnailCompress = (thumbnailCompressSize <=0 ? kThumbnailCompressSize : thumbnailCompressSize);
        CGFloat sourceCompress = (compressSize <=0 ? kCompressSize : compressSize);
        
        LFPhotoEdit *photoEdit = [self photoEditForAsset:asset];
        NSString *imageName = asset.name;
        
        /** 图片数据 */
        NSData *sourceData = nil; NSData *thumbnailData = nil;
        UIImage *thumbnail = nil; UIImage *source = nil;
        
        /** 原图 */
        source = photoEdit.editPreviewImage;
        sourceData = photoEdit.editPreviewData;
        
        BOOL isGif = source.images.count;
        
        if (isGif) { /** GIF图片处理方式 */
            if (!isOriginal) {
                CGFloat imageRatio = 0.7f;
                /** 标清图 */
                sourceData = [source lf_fastestCompressAnimatedImageDataWithScaleRatio:imageRatio];
                source = [UIImage LF_imageWithImageData:sourceData];
            }
        } else {
            if (!isOriginal) { /** 标清图 */
                NSData *newSourceData = [source lf_fastestCompressImageDataWithSize:sourceCompress imageSize:sourceData.length];
                if (newSourceData) {
                    /** 可压缩的 */
                    sourceData = newSourceData;
                    source = [UIImage LF_imageWithImageData:sourceData];
                }
            }
        }
        /** 图片宽高 */
        CGSize imageSize = source.size;
        
        if (thumbnailCompressSize > 0) {        
            if (isGif) {
                CGFloat minWidth = MIN(imageSize.width, imageSize.height);
                /** 缩略图 */
                CGFloat imageRatio = 0.5f;
                if (minWidth > 100.f) {
                    imageRatio = 50.f/minWidth;
                }
                /** 缩略图 */
                thumbnailData = [source lf_fastestCompressAnimatedImageDataWithScaleRatio:imageRatio];
                thumbnail = [UIImage LF_imageWithImageData:thumbnailData];
            } else {
                /** 缩略图 */
//                CGFloat aspectRatio = imageSize.width / (CGFloat)imageSize.height;
//                CGFloat th_pixelWidth = MIN(80, imageSize.width*0.5) * 2.0; // scale
//                CGFloat th_pixelHeight = th_pixelWidth / aspectRatio;
//                thumbnail = [source lf_scaleToSize:CGSizeMake(th_pixelWidth, th_pixelHeight)];
                NSData *newThumbnailData = [source lf_fastestCompressImageDataWithSize:thumbnailCompress imageSize:sourceData.length];
                if (newThumbnailData) {
                    /** 可压缩的 */
                    thumbnailData = newThumbnailData;
                } else {
                    thumbnailData = [NSData dataWithData:sourceData];
                }
                thumbnail = [UIImage LF_imageWithImageData:thumbnailData];
            }
        }
        
        LFResultImage *result = [LFResultImage new];
        result.asset = asset.asset;
        result.thumbnailImage = thumbnail;
        result.thumbnailData = thumbnailData;
        result.originalImage = source;
        result.originalData = sourceData;
        
        LFResultInfo *info = [LFResultInfo new];
        result.info = info;
        
        /** 图片文件名 */
        info.name = imageName;
        /** 图片大小 */
        info.byte = sourceData.length;
        /** 图片宽高 */
        info.size = imageSize;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result);
        });
    });
}
@end
#endif
