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
    } else if (asset.previewImage) {
        NSString *name = [NSString stringWithFormat:@"%zd", [asset.previewImage hash]];
        if (obj) {
            [weakSelf.photoEditDict setObject:obj forKey:name];
        } else {
            [weakSelf.photoEditDict removeObjectForKey:name];
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
    } else if (asset.previewImage) {
        NSString *name = [NSString stringWithFormat:@"%zd", [asset.previewImage hash]];
        photoEdit = [weakSelf.photoEditDict objectForKey:name];
    }
    return photoEdit;
}

/**
 通过asset解析缩略图、标清图/原图、图片数据字典
 
 @param asset PHAsset／ALAsset
 @param isOriginal 是否原图
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
               completion:(void (^)(LFResultImage *resultImage))completion
{
    [self getPhotoWithAsset:asset isOriginal:isOriginal compressSize:kCompressSize thumbnailCompressSize:kThumbnailCompressSize completion:completion];
}

/**
 通过asset解析缩略图、标清图/原图、图片数据字典
 
 @param asset PHAsset／ALAsset
 @param isOriginal 是否原图
 @param compressSize 非原图的压缩大小
 @param thumbnailCompressSize 缩略图压缩大小
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
             compressSize:(CGFloat)compressSize
    thumbnailCompressSize:(CGFloat)thumbnailCompressSize
               completion:(void (^)(LFResultImage *resultImage))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *thumbnail = nil;
        UIImage *source = nil;
        __block NSString *imageName = nil;
        
        __weak typeof(self) weakSelf = self;
        __block LFPhotoEdit *photoEdit = nil;
        [[LFAssetManager manager] requestForAsset:asset complete:^(NSString *name) {
            if (name.length) {
                photoEdit = [weakSelf.photoEditDict objectForKey:name];
                /** 图片文件名 */
                imageName = name;
            }
        }];
        
        /** 标清图/原图 */
        source = photoEdit.editPreviewImage;
        /** 图片数据 */
        NSData *imageData = nil;
        if (!isOriginal) { /** 标清图 */
            imageData = [source lf_fastestCompressImageDataWithSize:(compressSize <=0 ? kCompressSize : compressSize)];
            source = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
        } else {
            imageData = UIImageJPEGRepresentation(source, 0.75);
        }
        /** 图片宽高 */
        CGSize imageSize = source.size;
        
        /** 缩略图 */
        CGFloat aspectRatio = imageSize.width / (CGFloat)imageSize.height;
        CGFloat th_pixelWidth = 80 * 2.0; // scale
        CGFloat th_pixelHeight = th_pixelWidth / aspectRatio;
        thumbnail = [source lf_scaleToSize:CGSizeMake(th_pixelWidth, th_pixelHeight)];
        NSData *thumbnailData = [thumbnail lf_fastestCompressImageDataWithSize:(thumbnailCompressSize <=0 ? kThumbnailCompressSize : thumbnailCompressSize)];
        thumbnail = [UIImage imageWithData:thumbnailData scale:[UIScreen mainScreen].scale];
        
        LFResultImage *result = [LFResultImage new];
        result.asset = asset;
        result.thumbnailImage = thumbnail;
        result.thumbnailData = thumbnailData;
        result.originalImage = source;
        result.originalData = imageData;
        
        LFResultInfo *info = [LFResultInfo new];
        result.info = info;
        
        /** 图片文件名 */
        info.name = imageName;
        /** 图片大小 */
        info.byte = imageData.length;
        /** 图片宽高 */
        info.size = imageSize;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(result);
        });
    });
}
@end
#endif
