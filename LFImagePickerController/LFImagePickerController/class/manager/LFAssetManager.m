//
//  LFAssetManager.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"
#import "LFImagePickerHeader.h"
#import "UIImage+LF_ImageCompress.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_Format.h"
#import "LF_VideoUtils.h"
#import "LF_FileUtility.h"
#import "LFToGIF.h"
#import "LFResultObject_property.h"

#import <MobileCoreServices/UTCoreTypes.h>

@interface LFAssetManager ()

@end

@implementation LFAssetManager
@synthesize assetLibrary = _assetLibrary;

static CGFloat LFAM_ScreenWidth;
static CGFloat LFAM_ScreenScale;

static LFAssetManager *manager;
+ (instancetype)manager {

    if (manager == nil) {        
        manager = [[self alloc] init];
        manager.shouldFixOrientation = YES;
        LFAM_ScreenWidth = [UIScreen mainScreen].bounds.size.width;
        // 测试发现，如果scale在plus真机上取到3.0，内存会增大特别多。故这里写死成2.0
        LFAM_ScreenScale = 2.0;
        if (LFAM_ScreenWidth > 700) {
            LFAM_ScreenScale = 1.5;
        }
    }
    return manager;
}

+ (void)free
{
    manager = nil;
}

- (CGFloat)screenScale
{
    return LFAM_ScreenScale;
}

- (ALAssetsLibrary *)assetLibrary {
    if (_assetLibrary == nil) _assetLibrary = [[ALAssetsLibrary alloc] init];
    return _assetLibrary;
}

#pragma mark - Get Album

/// Get Album 获得相册/相册数组
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(LFAlbum *model))completion
{
    __block LFAlbum *model;
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
//        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:ascending]];
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
        if (iOS9Later) {
            option.fetchLimit = fetchLimit;
        }
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            // 有可能是PHCollectionList类的的对象，过滤掉
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            if ([self isCameraRollAlbum:collection.localizedTitle]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                model = [self modelWithResult:fetchResult album:collection];
                if (completion) completion(model);
                break;
            }
        }
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([self isCameraRollAlbum:name]) {
                model = [self modelWithResult:group album:nil];
                if (completion) completion(model);
                *stop = YES;
            }
        } failureBlock:nil];
    }
}

- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage ascending:(BOOL)ascending completion:(void (^)(NSArray<LFAlbum *> *))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    if (iOS8Later) {
        PHFetchOptions *option = [[PHFetchOptions alloc] init];
        if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
        
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];

        // 我的照片流 1.6.10重新加入..
        PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
        NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,syncedAlbums,sharedAlbums];
        for (PHFetchResult *fetchResult in allAlbums) {
            for (PHAssetCollection *collection in fetchResult) {
                // 有可能是PHCollectionList类的的对象，过滤掉
                if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
//                if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
                if ([self isCameraRollAlbum:collection.localizedTitle]) {
                    [albumArr insertObject:[self modelWithResult:fetchResult album:collection] atIndex:0];
                } else {
                    [albumArr addObject:[self modelWithResult:fetchResult album:collection]];
                }
            }
        }
        if (completion) completion(albumArr);
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion) completion(albumArr);
            }
//            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([self isCameraRollAlbum:name]) {
                [albumArr insertObject:[self modelWithResult:group album:nil] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                if (albumArr.count) {
                    [albumArr insertObject:[self modelWithResult:group album:nil] atIndex:1];
                } else {
                    [albumArr addObject:[self modelWithResult:group album:nil]];
                }
            } else {
                [albumArr addObject:[self modelWithResult:group album:nil]];
            }
        } failureBlock:^(NSError *error) {
            if (completion) completion(albumArr);
        }];
    }
}

#pragma mark - Get Assets

/// Get Assets 获得照片数组
- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(NSArray<LFAsset *> *models))completion
{
    __block NSMutableArray *photoArr = [NSMutableArray array];
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        NSUInteger count = fetchResult.count;
        
        NSInteger start = 0;
        if (fetchLimit > 0 && ascending == NO) { /** 重置起始值 */
            start = count > fetchLimit ? count - fetchLimit : 0;
        }
        
        NSInteger end = count;
        if (fetchLimit > 0 && ascending == NO) { /** 重置结束值 */
            end = count > fetchLimit ? fetchLimit : count;
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, end)];
        
        NSArray *results = [fetchResult objectsAtIndexes:indexSet];
        
        for (PHAsset *asset in results) {
            LFAsset *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
            if (model) {
                if (ascending) {
                    [photoArr addObject:model];
                } else {
                    [photoArr insertObject:model atIndex:0];
                }
            }
        }
        if (completion) completion(photoArr);
        
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        
        ALAssetsGroupEnumerationResultsBlock resultBlock = ^(ALAsset *asset, NSUInteger idx, BOOL *stop)
        {
            if (asset) {
                LFAsset *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
                if (model) {
                    [photoArr addObject:model];
                }
            }
            
        };
        
        NSUInteger count = group.numberOfAssets;
        
        NSInteger start = 0;
        if (fetchLimit > 0 && ascending == NO) { /** 重置起始值 */
            start = count > fetchLimit ? count - fetchLimit : 0;
        }
        
        NSInteger end = count;
        if (fetchLimit > 0 && ascending == NO) { /** 重置结束值 */
            end = count > fetchLimit ? fetchLimit : count;
        }
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(start, end)];
        [group enumerateAssetsUsingBlock:resultBlock];
    
        /** 排序 */
        [photoArr sortUsingComparator:^NSComparisonResult(LFAsset *  _Nonnull obj1, LFAsset *  _Nonnull obj2) {
            NSDate *date1 = [obj1.asset valueForProperty:ALAssetPropertyDate];
            NSDate *date2 = [obj2.asset valueForProperty:ALAssetPropertyDate];
            
            return ascending ? [date1 compare:date2] : [date2 compare:date1];
        }];
        
        /** 过滤 */
        NSArray *photos = [photoArr objectsAtIndexes:indexSet];
        
        if (completion) completion(photos);
    }
}

///  Get asset at index 获得下标为index的单个照片
///  if index beyond bounds, return nil in callback 如果索引越界, 在回调中返回 nil
- (void)getAssetFromFetchResult:(id)result
                        atIndex:(NSInteger)index
              allowPickingVideo:(BOOL)allowPickingVideo
              allowPickingImage:(BOOL)allowPickingImage
                      ascending:(BOOL)ascending
                     completion:(void (^)(LFAsset *))completion
{
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        PHAsset *asset;
        @try {
            asset = fetchResult[index];
        }
        @catch (NSException* e) {
            if (completion) completion(nil);
            return;
        }
        LFAsset *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
        if (completion) completion(model);
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        if (allowPickingImage && allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allAssets]];
        } else if (allowPickingVideo) {
            [group setAssetsFilter:[ALAssetsFilter allVideos]];
        } else if (allowPickingImage) {
            [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        }
        
        __block NSMutableArray *photoArr = [NSMutableArray array];
        
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if (result) {
                LFAsset *model = [self assetModelWithAsset:result allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
                [photoArr addObject:model];
            }
        }];
        
        /** 排序 */
        [photoArr sortUsingComparator:^NSComparisonResult(LFAsset *  _Nonnull obj1, LFAsset *  _Nonnull obj2) {
            NSDate *date1 = [obj1.asset valueForProperty:ALAssetPropertyDate];
            NSDate *date2 = [obj2.asset valueForProperty:ALAssetPropertyDate];
            
            return ascending ? [date1 compare:date2] : [date2 compare:date1];
        }];
        
        /** 过滤 */
        @try {
            LFAsset *model = [photoArr objectAtIndex:index];
            if (completion) completion(model);
        }
        @catch (NSException* e) {
            if (completion) completion(nil);
        }
    }
}

- (LFAsset *)assetModelWithAsset:(id)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
    LFAsset *model = [[LFAsset alloc] initWithAsset:asset];
    
    if (!allowPickingVideo && model.type == LFAssetMediaTypeVideo) return nil;
    if (!allowPickingImage && model.type == LFAssetMediaTypePhoto) return nil;
    
    return model;
}

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray <LFAsset *>*)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        LFAsset *model = photos[i];
        if ([model.asset isKindOfClass:[PHAsset class]]) {
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if (model.type != LFAssetMediaTypeVideo) dataLength += imageData.length;
                assetCount ++;
                if (assetCount >= photos.count) {
                    NSString *bytes = [self getBytesFromDataLength:dataLength];
                    if (completion) completion(bytes);
                }
            }];
        } else if ([model.asset isKindOfClass:[ALAsset class]]) {
            ALAssetRepresentation *representation = [model.asset defaultRepresentation];
            if (model.type != LFAssetMediaTypeVideo) dataLength += (NSInteger)representation.size;
            if (i >= photos.count - 1) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion) completion(bytes);
            }
        }
    }
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

#pragma mark - Get Photo

/// Get photo 获得照片本身
- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    CGFloat fullScreenWidth = LFAM_ScreenWidth;
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:nil networkAccessAllowed:YES];
}

- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    return [self getPhotoWithAsset:asset photoWidth:photoWidth completion:completion progressHandler:nil networkAccessAllowed:YES];
}

- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    if ([asset isKindOfClass:[PHAsset class]]) {
        
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * LFAM_ScreenScale;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
        // 修复获取图片时出现的瞬间内存过高问题
        // 下面两行代码，来自hsjcom，他的github是：https://github.com/hsjcom 表示感谢
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && result) {
                if (self.shouldFixOrientation) {
                    result = [result lf_fixOrientation];
                }
                if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            }
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    dispatch_main_async_safe(^{
                        if (progressHandler) {
                            progressHandler(progress, error, stop, info);
                        }
                    });
                };
                options.networkAccessAllowed = YES;
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:[UIScreen mainScreen].scale];
                    resultImage = [resultImage lf_scaleToSize:imageSize];
                    if (resultImage) {
                        if (self.shouldFixOrientation) {
                            resultImage = [resultImage lf_fixOrientation];
                        }
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
        return imageRequestID;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        
        if (photoWidth > [UIScreen mainScreen].bounds.size.width/2) {
            dispatch_globalQueue_async_safe(^{
                ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:2.0 orientation:UIImageOrientationUp];
                
                dispatch_main_async_safe(^{
                    if (completion) completion(fullScrennImage,nil,NO);
                });
            });
        } else {            
            dispatch_globalQueue_async_safe(^{
                CGImageRef thumbnailImageRef = alAsset.thumbnail;
                UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:2.0 orientation:UIImageOrientationUp];
                dispatch_main_async_safe(^{
                    if (completion) completion(thumbnailImage,nil,NO);
                });
            });
        }
        
    }
    return 0;
}

#pragma mark - Get photo data (gif)
- (PHImageRequestID)getPhotoDataWithAsset:(id)asset completion:(void (^)(NSData *data,NSDictionary *info,BOOL isDegraded))completion
{
    return [self getPhotoDataWithAsset:asset completion:completion progressHandler:nil networkAccessAllowed:YES];
}
- (PHImageRequestID)getPhotoDataWithAsset:(id)asset completion:(void (^)(NSData *data,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && imageData) {
                BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                if (completion) completion(imageData,info,isDegraded);
            }
            
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !imageData && networkAccessAllowed) {
                PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
                options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    dispatch_main_async_safe(^{
                        if (progressHandler) {
                            progressHandler(progress, error, stop, info);
                        }
                    });
                };
                options.networkAccessAllowed = YES;
                options.resizeMode = PHImageRequestOptionsResizeModeFast;
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                    if (completion) completion(imageData,info,isDegraded);
                }];
            }
        }];
        return imageRequestID;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        Byte *imageBuffer = (Byte *)malloc((size_t)assetRep.size);
        NSUInteger bufferSize = [assetRep getBytes:imageBuffer fromOffset:0.0 length:(NSInteger)assetRep.size error:nil];
        NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
        if (completion) completion(imageData,nil,NO);
    }
    return 0;
}

#pragma mark - Get live photo

- (PHImageRequestID)getLivePhotoWithAsset:(id)asset completion:(void (^)(PHLivePhoto *livePhoto,NSDictionary *info,BOOL isDegraded))completion {
    CGFloat fullScreenWidth = LFAM_ScreenWidth;
    return [self getLivePhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:nil networkAccessAllowed:NO];
}

- (PHImageRequestID)getLivePhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(PHLivePhoto *livePhoto,NSDictionary *info,BOOL isDegraded))completion {
    return [self getLivePhotoWithAsset:asset photoWidth:photoWidth completion:completion progressHandler:nil networkAccessAllowed:NO];
}

- (PHImageRequestID)getLivePhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(PHLivePhoto *livePhoto,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    
    if (iOS9_1Later && [asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * LFAM_ScreenScale;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
        
        PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc]init];
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        PHImageRequestID imageRequestID = [[PHImageManager defaultManager] requestLivePhotoForAsset:phAsset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && livePhoto) {
                BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                if (completion) completion(livePhoto,info,isDegraded);
            }
            
            // Download image from iCloud / 从iCloud下载图片
            if ([info objectForKey:PHImageResultIsInCloudKey] && !livePhoto && networkAccessAllowed) {
                PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc]init];
                options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                    dispatch_main_async_safe(^{
                        if (progressHandler) {
                            progressHandler(progress, error, stop, info);
                        }
                    });
                };
                options.networkAccessAllowed = YES;
                options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                [[PHImageManager defaultManager] requestLivePhotoForAsset:phAsset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
                    
                    BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                    if (completion) completion(livePhoto,info,isDegraded);
                }];
            }
        }];
        return imageRequestID;
    }
    return 0;
}

/**
 *  通过asset解析缩略图、标清图/原图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param isOriginal 是否原图
 *  @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
               completion:(void (^)(LFResultImage *resultImage))completion
{
    [self getPhotoWithAsset:asset isOriginal:isOriginal pickingGif:NO completion:completion];
}

/**
 *  通过asset解析缩略图、标清图/原图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param isOriginal 是否原图
 *  @param pickingGif 是否需要处理GIF图片
 *  @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
               pickingGif:(BOOL)pickingGif
               completion:(void (^)(LFResultImage *resultImage))completion
{
    [self getPhotoWithAsset:asset isOriginal:isOriginal pickingGif:pickingGif compressSize:kCompressSize thumbnailCompressSize:kThumbnailCompressSize completion:completion];
}


/**
 通过asset解析缩略图、标清图/原图、图片数据字典

 @param asset PHAsset／ALAsset
 @param isOriginal 是否原图
 @param pickingGif 是否需要处理GIF图片
 @param compressSize 非原图的压缩大小
 @param thumbnailCompressSize 缩略图压缩大小
 @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset
               isOriginal:(BOOL)isOriginal
               pickingGif:(BOOL)pickingGif
             compressSize:(CGFloat)compressSize
    thumbnailCompressSize:(CGFloat)thumbnailCompressSize
               completion:(void (^)(LFResultImage *resultImage))completion
{
    [self getBasePhotoWithAsset:asset completion:^(NSData *imageData, NSString *imageName, LFImagePickerSubMediaType subMediaType) {
        
        dispatch_globalQueue_async_safe(^{
            CGFloat thumbnailCompress = (thumbnailCompressSize <=0 ? kThumbnailCompressSize : thumbnailCompressSize);
            CGFloat sourceCompress = (compressSize <=0 ? kCompressSize : compressSize);
            BOOL isGif = subMediaType == LFImagePickerSubMediaTypeGIF;
            //        BOOL isLivePhoto = [info[kImageInfoMediaType] integerValue] == LFImagePickerSubMediaTypeLivePhoto;
            NSData *sourceData = nil; NSData *thumbnailData = nil;
            UIImage *thumbnail = nil; UIImage *source = nil;
            
            LFImagePickerSubMediaType mediaType = subMediaType;
            
            /** 原图 */
            source = [UIImage LF_imageWithImageData:imageData];
            
            if (isGif && pickingGif) { /** GIF图片处理方式 */
                
                CGFloat minWidth = MIN(source.size.width, source.size.height);
                CGFloat imageRatio = 0.7f;
                
                if (!isOriginal) {
                    /** 标清图 */
                    sourceData = [source lf_fastestCompressAnimatedImageDataWithScaleRatio:imageRatio];
                }
                /** 缩略图 */
                imageRatio = 0.5f;
                if (minWidth > 100.f) {
                    imageRatio = 50.f/minWidth;
                }
                /** 缩略图 */
                thumbnailData = [source lf_fastestCompressAnimatedImageDataWithScaleRatio:imageRatio];
                
            } else {
                
                /** 原图方向更正 */
                BOOL isFixOrientation = NO;
                if (self.shouldFixOrientation && source.imageOrientation != UIImageOrientationUp) {
                    source = [source lf_fixOrientation];
                    isFixOrientation = YES;
                }
                
                /** 重写标记 */
                mediaType = LFImagePickerSubMediaTypeNone;
                
                /** 标清图 */
                if (!isOriginal) {
                    sourceData = [source lf_fastestCompressImageDataWithSize:sourceCompress];
                } else {
                    if (isFixOrientation) { /** 更正方向，原图data需要更新 */
                        sourceData = UIImageJPEGRepresentation(source, 1);
                    }
                }
                /** 缩略图 */
                thumbnailData = [source lf_fastestCompressImageDataWithSize:thumbnailCompress];
            }
            
            /** 创建展示图片 */
            if (thumbnailData) {
                /** 缩略图数据 */
                thumbnail = [UIImage LF_imageWithImageData:thumbnailData];
            }
            if (sourceData) {
                source = [UIImage LF_imageWithImageData:sourceData];
            }
            
            NSData *originalData = sourceData ?: imageData;
            
            /** 图片宽高 */
            CGSize imageSize = source.size;
            
            LFResultImage *result = [LFResultImage new];
            result.asset = asset;
            result.thumbnailImage = thumbnail;
            result.thumbnailData = thumbnailData;
            result.originalImage = source;
            result.originalData = originalData;
            result.subMediaType = mediaType;
            
            LFResultInfo *info = [LFResultInfo new];
            result.info = info;
            
            /** 图片文件名 */
            info.name = imageName;
            /** 图片大小 */
            info.byte = originalData.length;
            /** 图片宽高 */
            info.size = imageSize;
            
            dispatch_main_async_safe(^{
                if (completion) {
                    completion(result);
                }
            });
        });
    }];
}


/**
 基础方法
 
 @param asset PHAsset／ALAsset
 @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getBasePhotoWithAsset:(id)asset completion:(void (^)(NSData *imageData, NSString *imageName, LFImagePickerSubMediaType subMediaType))completion
{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        
        // 修复获取图片时出现的瞬间内存过高问题
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        /** 图片文件名+图片大小 */
        [[PHImageManager defaultManager] requestImageDataForAsset:phAsset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            
            NSString *fileName = [phAsset valueForKey:@"filename"];
            
            LFImagePickerSubMediaType mediaType = LFImagePickerSubMediaTypeNone;
            if (iOS9_1Later && phAsset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                mediaType = LFImagePickerSubMediaTypeLivePhoto;
            } else if ([[phAsset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                mediaType = LFImagePickerSubMediaTypeGIF;
            }
            
            if (completion) completion(imageData, fileName, mediaType);
        }];
        
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        
        dispatch_globalQueue_async_safe(^{
            ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
            
            LFImagePickerSubMediaType mediaType = LFImagePickerSubMediaTypeNone;
            ALAssetRepresentation *gifAR = [alAsset representationForUTI: (__bridge NSString *)kUTTypeGIF];
            if (gifAR) {
                mediaType = LFImagePickerSubMediaTypeGIF;
                
                assetRep = gifAR;
            }
            
            Byte *imageBuffer = (Byte *)malloc((size_t)assetRep.size);
            NSUInteger bufferSize = [assetRep getBytes:imageBuffer fromOffset:0.0 length:(NSInteger)assetRep.size error:nil];
            NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
            /** 文件名称 */
            NSString *fileName = assetRep.filename;
            
            dispatch_main_async_safe(^{
                if (completion) completion(imageData, fileName, mediaType);
            });
        });
    }
}

- (void)getLivePhotoWithAsset:(id)asset isOriginal:(BOOL)isOriginal completion:(void (^)(LFResultImage *resultImage))completion
{
    if (iOS9_1Later && [asset isKindOfClass:[PHAsset class]]) {
        
        PHAsset *phAsset = (PHAsset *)asset;
        
        PHLivePhotoRequestOptions *option = [[PHLivePhotoRequestOptions alloc]init];
        option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        [[PHImageManager defaultManager] requestLivePhotoForAsset:phAsset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            
            NSString *fileName = [phAsset valueForKey:@"filename"];

            NSString *fileFirstName = [fileName stringByDeletingPathExtension];
            
            NSArray *resourceArray = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
            PHAssetResourceManager *arm = [PHAssetResourceManager defaultManager];
            PHAssetResource *assetResource = resourceArray.lastObject;
            NSString *cache = [LFAssetManager CacheVideoPath];
            NSString *filePath = [cache stringByAppendingPathComponent:[fileFirstName stringByAppendingPathExtension:@"mov"]];
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
            
            NSURL *videoURL = [[NSURL alloc] initFileURLWithPath:filePath];
            
            void (^livePhotoToGif)(NSURL *) = ^(NSURL *videoURL){
                [LFToGIF optimalGIFfromURL:videoURL loopCount:0 completion:^(NSURL *GifURL) {
                    
                    if (GifURL) {
                        
                        /** 图片数据 */
                        NSData *imageData = [NSData dataWithContentsOfURL:GifURL];
                        /** 图片名称 */
                        NSString *imageName = [fileFirstName stringByAppendingPathExtension:@"gif"];
                        
                        /** 原图 */
                        UIImage *source = [UIImage LF_imageWithImageData:imageData];
                        
                        /** 缩略图 */
                        CGFloat minWidth = MIN(source.size.width, source.size.height);
                        CGFloat imageRatio = 0.5f;
                        if (minWidth > 100.f) {
                            imageRatio = 50.f/minWidth;
                        }
                        /** 缩略图 */
                        NSData *thumbnailData = [source lf_fastestCompressAnimatedImageDataWithScaleRatio:imageRatio];
                        UIImage *thumbnail = [UIImage LF_imageWithImageData:thumbnailData];
                        
                        /** 图片宽高 */
                        CGSize imageSize = source.size;
                        
                        LFResultImage *result = [LFResultImage new];
                        result.asset = asset;
                        result.thumbnailImage = thumbnail;
                        result.thumbnailData = thumbnailData;
                        result.originalImage = source;
                        result.originalData = imageData;
                        result.subMediaType = LFImagePickerSubMediaTypeGIF;
                        
                        LFResultInfo *info = [LFResultInfo new];
                        result.info = info;
                        
                        /** 图片文件名 */
                        info.name = imageName;
                        /** 图片大小 */
                        info.byte = imageData.length;
                        /** 图片宽高 */
                        info.size = imageSize;
                        
                        if (completion) completion(result);
                    } else {
                        if (completion) completion(nil);
                    }
                }];
            };
            
            
            if (isExists) {
                livePhotoToGif(videoURL);
            } else {
                [arm writeDataForAssetResource:assetResource toFile:videoURL options:nil completionHandler:^(NSError * _Nullable error)
                 {
                     if (error) {
                         [self getPhotoWithAsset:phAsset isOriginal:isOriginal completion:completion];
                     } else {
                         livePhotoToGif(videoURL);
                     }
                 }];
            }
            
        }];
    } else {
        if (completion) completion(nil);
    }
}

#pragma mark - Get Video

/// Get Video / 获取视频
- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            dispatch_main_async_safe(^{
                if (completion) completion(playerItem,info);
            });
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[asset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem) {
            dispatch_main_async_safe(^{
                completion(playerItem,nil);
            });
        }
    }
}

- (void)getVideoResultWithAsset:(id)asset completion:(void (^)(LFResultVideo *resultVideo))completion
{
    NSString *name = nil;
    if ([asset isKindOfClass:[PHAsset class]]) {
        name = [asset valueForKey:@"filename"];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        name = assetRep.filename;
    }
    if (![name hasSuffix:@".mp4"]) {
        name = [name stringByDeletingPathExtension];
        name = [name stringByAppendingPathExtension:@"mp4"];
    }
    
    void(^VideoResultComplete)(NSString *videoPath) = ^(NSString *videoPath) {
        
        [[LFAssetManager manager] getPhotoWithAsset:asset photoWidth:LFAM_ScreenWidth completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (isDegraded == NO) {
                LFResultVideo *result = [LFResultVideo new];
                result.asset = asset;
                result.coverImage = photo;
                if (videoPath.length) {
                    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
                    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoPath] options:opts];
                    NSData *data = [NSData dataWithContentsOfFile:videoPath];
                    NSTimeInterval duration = CMTimeGetSeconds(urlAsset.duration);
                    
                    NSArray *assetVideoTracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
                    CGSize size = CGSizeZero;
                    if (assetVideoTracks.count > 0)
                    {
                        // Insert the tracks in the composition's tracks
                        AVAssetTrack *track = [assetVideoTracks firstObject];
                        
                        CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
                        size = CGSizeMake(fabs(dimensions.width), fabs(dimensions.height));
                    }
                    
                    
                    result.data = data;
                    result.url = [NSURL fileURLWithPath:videoPath];
                    result.duration = duration;
                    
                    LFResultInfo *info = [LFResultInfo new];
                    result.info = info;
                    
                    /** 文件名 */
                    info.name = name;
                    /** 大小 */
                    info.byte = data.length;
                    /** 宽高 */
                    info.size = size;
                }
                if (completion) {
                    completion(result);
                }
            }
        } progressHandler:nil networkAccessAllowed:NO];
    };
    
    NSString *videoPath = [[LFAssetManager CacheVideoPath] stringByAppendingPathComponent:name];
    /** 判断视频是否存在 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        if (VideoResultComplete) VideoResultComplete(videoPath);
    } else {
        [self compressAndCacheVideoWithAsset:asset completion:^(NSString *path) {
            if (VideoResultComplete) VideoResultComplete(path);
        }];
    }
    
}

/**
 *  @author lincf, 16-06-15 13:06:26
 *
 *  视频压缩并缓存压缩后视频 (将视频格式变为mp4)
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 回调压缩后视频路径，可以复制或剪切
 */
- (void)compressAndCacheVideoWithAsset:(id)asset completion:(void (^)(NSString *path))completion
{
    if (completion == nil) return;
    NSString *cache = [LFAssetManager CacheVideoPath];
    NSString *name = nil;
    if ([asset isKindOfClass:[PHAsset class]]) {
        name = [asset valueForKey:@"filename"];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        name = assetRep.filename;
    }
    if (![name hasSuffix:@".mp4"]) {
        name = [name stringByDeletingPathExtension];
        name = [name stringByAppendingPathExtension:@"mp4"];
    }
    NSString *path = [cache stringByAppendingPathComponent:name];
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable av_asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            [LF_VideoUtils encodeVideoWithAsset:av_asset outPath:path complete:^(BOOL isSuccess, NSError *error) {
                if (error) {
                    dispatch_main_async_safe(^{
                        completion(nil);
                    });
                }else{
                    dispatch_main_async_safe(^{
                        completion(path);
                    });
                }
            }];
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        NSURL *videoURL = [rep url];
        [LF_VideoUtils encodeVideoWithURL:videoURL outPath:path complete:^(BOOL isSuccess, NSError *error) {
            if (error) {
                dispatch_main_async_safe(^{
                    completion(nil);
                });
            }else{
                dispatch_main_async_safe(^{
                    completion(path);
                });
            }
        }];
    }else{
        dispatch_main_async_safe(^{
            completion(nil);
        });
    }
}

/// Get postImage / 获取封面图
- (void)getPostImageWithAlbumModel:(LFAlbum *)model ascending:(BOOL)ascending completion:(void (^)(UIImage *))completion {
    if (iOS8Later) {
        id asset = [model.result lastObject];
        if (!ascending) {
            asset = [model.result firstObject];
        }
        [self getPhotoWithAsset:asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completion) completion(photo);
        }];
    } else {
        ALAssetsGroup *group = model.result;
        UIImage *postImage = [UIImage imageWithCGImage:group.posterImage];
        if (completion) completion(postImage);
    }
}

/// Judge is a assets array contain the asset 判断一个assets数组是否包含这个asset
- (NSInteger)isAssetsArray:(NSArray *)assets containAsset:(id)asset {
    if (iOS8Later) {
        return [assets indexOfObject:asset];
    } else {
        NSMutableArray *selectedAssetUrls = [NSMutableArray array];
        for (ALAsset *asset_item in assets) {
            [selectedAssetUrls addObject:[asset_item valueForProperty:ALAssetPropertyURLs]];
        }
        return [selectedAssetUrls indexOfObject:[asset valueForProperty:ALAssetPropertyURLs]];
    }
}

- (BOOL)isCameraRollAlbum:(NSString *)albumName {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 - 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return [albumName isEqualToString:@"最近添加"] || [albumName isEqualToString:@"Recently Added"];
    } else {
        return [albumName isEqualToString:@"Camera Roll"] || [albumName isEqualToString:@"相机胶卷"] || [albumName isEqualToString:@"所有照片"] || [albumName isEqualToString:@"All Photos"];
    }
}

- (NSString *)getAssetIdentifier:(id)asset {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        return phAsset.localIdentifier;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        NSURL *assetUrl = [alAsset valueForProperty:ALAssetPropertyAssetURL];
        return assetUrl.absoluteString;
    }
    return nil;
}

/// 检查照片大小是否满足最小要求
- (BOOL)isPhotoSelectableWithAsset:(id)asset {
    if (self.minPhotoWidthSelectable > 0 || self.minPhotoHeightSelectable > 0) {        
        CGSize photoSize = [self photoSizeWithAsset:asset];
        if (self.minPhotoWidthSelectable > photoSize.width || self.minPhotoHeightSelectable > photoSize.height) {
            return NO;
        }
    }
    return YES;
}

- (CGSize)photoSizeWithAsset:(id)asset {
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        return CGSizeMake(phAsset.pixelWidth, phAsset.pixelHeight);
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        return alAsset.defaultRepresentation.dimensions;
    }
    return CGSizeZero;
}

- (void)requestForAsset:(id)asset complete:(void (^)(NSString *name))complete
{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        NSString *fileName = [phAsset valueForKey:@"filename"];
        if (complete) complete(fileName);
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        NSString *fileName = assetRep.filename;
        if (complete) complete(fileName);
    }
}

#pragma mark - Private Method

- (LFAlbum *)modelWithResult:(id)result album:(id)album{
    LFAlbum *model = [[LFAlbum alloc] initWithAlbum:album result:result];
    return model;
}

/// Return Cache Path
+ (NSString *)CacheVideoPath
{
    NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleIdentifierKey];
    NSString *fullNamespace = [bundleId stringByAppendingPathComponent:@"videoCache"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths.firstObject stringByAppendingPathComponent:fullNamespace];
    
    [LF_FileUtility createFolder:cachePath errStr:nil];
    
    return cachePath;
}

+ (BOOL)cleanCacheVideoPath
{
    NSString *path = [self CacheVideoPath];
    return [LF_FileUtility removeFile:path];
}

- (NSURL *)getURLInPlayer:(AVPlayer *)player
{
    // get current asset
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    // return the NSURL
    return [(AVURLAsset *)currentPlayerAsset URL];
}

@end
