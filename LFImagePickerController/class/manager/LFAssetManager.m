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
#import "LF_VideoUtils.h"
#import "LF_FileUtility.h"

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
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        for (PHAssetCollection *collection in smartAlbums) {
            // 有可能是PHCollectionList类的的对象，过滤掉
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            if ([self isCameraRollAlbum:collection.localizedTitle]) {
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                model = [self modelWithResult:fetchResult name:collection.localizedTitle];
                if (completion) completion(model);
                break;
            }
        }
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([self isCameraRollAlbum:name]) {
                model = [self modelWithResult:group name:name];
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
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
        PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
        NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
        for (PHFetchResult *fetchResult in allAlbums) {
            for (PHAssetCollection *collection in fetchResult) {
                // 有可能是PHCollectionList类的的对象，过滤掉
                if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                if (fetchResult.count < 1) continue;
                if ([collection.localizedTitle containsString:@"Deleted"] || [collection.localizedTitle isEqualToString:@"最近删除"]) continue;
                if ([self isCameraRollAlbum:collection.localizedTitle]) {
                    [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle] atIndex:0];
                } else {
                    [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle]];
                }
            }
        }
        if (completion && albumArr.count > 0) completion(albumArr);
    } else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                if (completion && albumArr.count > 0) completion(albumArr);
            }
            if ([group numberOfAssets] < 1) return;
            NSString *name = [group valueForProperty:ALAssetsGroupPropertyName];
            if ([self isCameraRollAlbum:name]) {
                [albumArr insertObject:[self modelWithResult:group name:name] atIndex:0];
            } else if ([name isEqualToString:@"My Photo Stream"] || [name isEqualToString:@"我的照片流"]) {
                if (albumArr.count) {
                    [albumArr insertObject:[self modelWithResult:group name:name] atIndex:1];
                } else {
                    [albumArr addObject:[self modelWithResult:group name:name]];
                }
            } else {
                [albumArr addObject:[self modelWithResult:group name:name]];
            }
        } failureBlock:nil];
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
                    if (ascending) {
                        [photoArr insertObject:model atIndex:0];
                    } else {
                        [photoArr addObject:model];
                    }
                    
                }
                if (fetchLimit > 0 && photoArr.count == fetchLimit) {
                    *stop = YES;
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
        [group enumerateAssetsAtIndexes:indexSet options:NSEnumerationReverse usingBlock:resultBlock];
        
        if (completion) completion(photoArr);
    }
}

///  Get asset at index 获得下标为index的单个照片
///  if index beyond bounds, return nil in callback 如果索引越界, 在回调中返回 nil
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(LFAsset *))completion {
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
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        @try {
            [group enumerateAssetsAtIndexes:indexSet options:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (!result) return;
                LFAsset *model = [self assetModelWithAsset:result allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
                if (completion) completion(model);
            }];
        }
        @catch (NSException* e) {
            if (completion) completion(nil);
        }
    }
}

- (LFAsset *)assetModelWithAsset:(id)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
    LFAsset *model;
    LFAssetMediaType type = LFAssetMediaTypePhoto;
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        if (phAsset.mediaType == PHAssetMediaTypeVideo)      type = LFAssetMediaTypeVideo;
        else if (phAsset.mediaType == PHAssetMediaTypeAudio) type = LFAssetMediaTypeAudio;
        else if (phAsset.mediaType == PHAssetMediaTypeImage) {
            if (iOS9_1Later) {
                // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = LFAssetMediaTypeLivePhoto;
            }
        }
        if (!allowPickingVideo && type == LFAssetMediaTypeVideo) return nil;
        if (!allowPickingImage && type == LFAssetMediaTypePhoto) return nil;
        
        // 过滤掉尺寸不满足要求的图片
        if (![self isPhotoSelectableWithAsset:phAsset]) {
            return nil;
        }

        NSString *timeLength = type == LFAssetMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",phAsset.duration] : @"";
        timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
        model = [[LFAsset alloc] initWithAsset:asset type:type timeLength:timeLength];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        if (!allowPickingVideo){
            model = [[LFAsset alloc] initWithAsset:asset type:type];
            return model;
        }
        /// Allow picking video
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            type = LFAssetMediaTypeVideo;
            NSTimeInterval duration = [[asset valueForProperty:ALAssetPropertyDuration] integerValue];
            NSString *timeLength = [NSString stringWithFormat:@"%0.0f",duration];
            timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
            model = [[LFAsset alloc] initWithAsset:asset type:type timeLength:timeLength];
        } else {
            // 过滤掉尺寸不满足要求的图片
            if (![self isPhotoSelectableWithAsset:asset]) {
                return nil;
            }

            model = [[LFAsset alloc] initWithAsset:asset type:type];
        }
    }
    return model;
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray <LFAsset *>*)photos completion:(void (^)(NSString *totalBytes))completion {
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        LFAsset *model = photos[i];
        if ([model.asset isKindOfClass:[PHAsset class]]) {
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
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

- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    CGFloat fullScreenWidth = LFAM_ScreenWidth;
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:progressHandler networkAccessAllowed:networkAccessAllowed];
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
                    result = [result fixOrientation];
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
                    UIImage *resultImage = [UIImage imageWithData:imageData scale:0.1];
                    resultImage = [resultImage scaleToSize:imageSize];
                    if (resultImage) {
                        if (self.shouldFixOrientation) {
                            resultImage = [resultImage fixOrientation];
                        }
                        if (completion) completion(resultImage,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                    }
                }];
            }
        }];
        return imageRequestID;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        dispatch_globalQueue_async_safe(^{
            CGImageRef thumbnailImageRef = alAsset.thumbnail;
            UIImage *thumbnailImage = [UIImage imageWithCGImage:thumbnailImageRef scale:2.0 orientation:UIImageOrientationUp];
            dispatch_main_async_safe(^{
                if (completion) completion(thumbnailImage,nil,YES);
                
                dispatch_globalQueue_async_safe(^{
                    ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
                    CGImageRef fullScrennImageRef = [assetRep fullScreenImage];
                    UIImage *fullScrennImage = [UIImage imageWithCGImage:fullScrennImageRef scale:2.0 orientation:UIImageOrientationUp];
                    
                    dispatch_main_async_safe(^{
                        if (completion) completion(fullScrennImage,nil,NO);
                    });
                });
            });
        });
    }
    return 0;
}

/**
 *  通过asset解析缩略图、标清图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPreviewPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, UIImage *, NSDictionary *))completion
{
    [self getPhotoWithAsset:asset isOrigin:NO completion:^(UIImage *thumbnail, UIImage *source, NSMutableDictionary *info) {
        thumbnail = [thumbnail fastestCompressImageWithSize:10];
        
        NSData *sourceData = [source fastestCompressImageDataWithSize:100];
        source = [UIImage imageWithData:sourceData];
        /** 图片宽高 */
        CGSize imageSize = source.size;
        NSValue *value = [NSValue valueWithBytes:&imageSize objCType:@encode(CGSize)];
        [info setObject:value forKey:kImageInfoFileSize];
        /** 图片大小 */
        [info setObject:@(sourceData.length) forKey:kImageInfoFileByte];
        
        if (completion) {
            completion(thumbnail, source, info);
        }
    }];
}

/**
 *  通过asset解析缩略图、原图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getOriginPhotoWithAsset:(id)asset completion:(void (^)(UIImage *, UIImage *, NSDictionary *))completion
{
    [self getPhotoWithAsset:asset isOrigin:YES completion:^(UIImage *thumbnail, UIImage *source, NSMutableDictionary *info) {
        thumbnail = [thumbnail fastestCompressImageWithSize:10];
        /** 图片宽高 */
        CGSize imageSize = source.size;
        NSValue *value = [NSValue valueWithBytes:&imageSize objCType:@encode(CGSize)];
        [info setObject:value forKey:kImageInfoFileSize];
        
        if (completion) {
            completion(thumbnail, source, info);
        }
    }];
}


/**
 基础方法
 
 @param asset PHAsset／ALAsset
 @param isOrigin 是否获取原图
 @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getPhotoWithAsset:(id)asset isOrigin:(BOOL)isOrigin completion:(void (^)(UIImage *, UIImage *, NSMutableDictionary *))completion
{
    __block UIImage *thumbnail = nil;
    __block UIImage *source = nil;
    NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
    CGSize size = PHImageManagerMaximumSize;
    
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat th_pixelWidth = 80 * LFAM_ScreenScale;
        CGFloat th_pixelHeight = th_pixelWidth / aspectRatio;
        
        // 修复获取图片时出现的瞬间内存过高问题
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        /** 缩略图 */
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:CGSizeMake(th_pixelWidth, th_pixelHeight) contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]&& ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined) {
                if (self.shouldFixOrientation) {
                    thumbnail = [result fixOrientation];
                } else {
                    thumbnail = result;
                }
                if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
            }
        }];
        if (isOrigin == NO) {
            CGFloat pixelWidth = LFAM_ScreenWidth * 0.5 * LFAM_ScreenScale;
            CGFloat pixelHeight = pixelWidth / aspectRatio;
            size = CGSizeMake(pixelWidth, pixelHeight);
        }
        /** 标清图／原图 */
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]&& ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
            if (downloadFinined) {
                if (self.shouldFixOrientation) {
                    source = [result fixOrientation];
                } else {
                    source = result;
                }
                
                if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
            }
        }];
        
        /** 图片文件名+图片大小 */
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            /** 图片大小 */
            [imageInfo setObject:@(imageData.length) forKey:kImageInfoFileByte];
            
            NSURL *fileUrl = [info objectForKey:@"PHImageFileURLKey"];
            if (fileUrl) {
                [imageInfo setObject:fileUrl.lastPathComponent forKey:kImageInfoFileName];
            } else {
                [imageInfo setObject:[NSNull null] forKey:kImageInfoFileName];
            }
            if (completion && thumbnail && source && imageInfo.count) completion(thumbnail, source, imageInfo);
        }];
        
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        CGImageRef thumbnailImageRef = alAsset.aspectRatioThumbnail;/** 缩略图 */
        thumbnail = [UIImage imageWithCGImage:thumbnailImageRef scale:1.0 orientation:UIImageOrientationUp];
        if (self.shouldFixOrientation) {
            thumbnail = [thumbnail fixOrientation];
        }
        
        dispatch_globalQueue_async_safe(^{
            
            if (isOrigin) {
                CGImageRef fullResolutionImageRef = [assetRep fullResolutionImage]; /** 原图 */
                // 通过 fullResolutionImage 获取到的的高清图实际上并不带上在照片应用中使用“编辑”处理的效果，需要额外在 AlAssetRepresentation 中获取这些信息
                NSString *adjustment = [[assetRep metadata] objectForKey:@"AdjustmentXMP"];
                if (adjustment) {
                    // 如果有在照片应用中使用“编辑”效果，则需要获取这些编辑后的滤镜，手工叠加到原图中
                    NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
                    CIImage *tempImage = [CIImage imageWithCGImage:fullResolutionImageRef];
                    
                    NSError *error;
                    NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                                 inputImageExtent:tempImage.extent
                                                                            error:&error];
                    CIContext *context = [CIContext contextWithOptions:nil];
                    if (filterArray && !error) {
                        for (CIFilter *filter in filterArray) {
                            [filter setValue:tempImage forKey:kCIInputImageKey];
                            tempImage = [filter outputImage];
                        }
                        fullResolutionImageRef = [context createCGImage:tempImage fromRect:[tempImage extent]];
                    }
                }
                // 生成最终返回的 UIImage，同时把图片的 orientation 也补充上去
                source = [UIImage imageWithCGImage:fullResolutionImageRef scale:[assetRep scale] orientation:(UIImageOrientation)[assetRep orientation]];
            } else {
                CGImageRef fullScrennImageRef = [assetRep fullScreenImage]; /** 标清图 */
                source = [UIImage imageWithCGImage:fullScrennImageRef scale:1.0 orientation:UIImageOrientationUp];
            }
            if (self.shouldFixOrientation) {
                source = [source fixOrientation];
            }
            
            NSString *fileName = assetRep.filename;
            if (fileName.length) {
                [imageInfo setObject:fileName forKey:kImageInfoFileName];
            }
            
            /** 相册没有生成缩略图 */
            if (thumbnail == nil) {
                thumbnail = source;
            }
            
            
            dispatch_main_async_safe(^{
                if (completion) completion(thumbnail, source, imageInfo);
            });
        });
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
    if ([asset isKindOfClass:[PHAsset class]]) {
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                NSURL *url = ((AVURLAsset *)asset).URL;
                if (url) {
                    NSString *videoName = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingString:@".mp4"];
                    NSString *path = [cache stringByAppendingPathComponent:videoName];
                    
                    [LF_VideoUtils encodeVideoWithAsset:asset outPath:path complete:^(BOOL isSuccess, NSError *error) {
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
                } else {
                    dispatch_main_async_safe(^{
                        completion(nil);
                    });
                }
            } else {
                dispatch_main_async_safe(^{
                    completion(nil);
                });
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        NSString *videoName = [rep filename];
        NSURL *videoURL = [rep url];
        if (videoName.length && videoURL) {
            NSString *path = [cache stringByAppendingPathComponent:videoName];
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
            [LF_VideoUtils encodeVideoWithAsset:asset outPath:path complete:^(BOOL isSuccess, NSError *error) {
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
        } else {
            dispatch_main_async_safe(^{
                completion(nil);
            });
        }
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

/// Get Original Photo / 获取原图
- (void)getOriginalPhotoWithAsset:(id)asset completion:(void (^)(NSData *data, UIImage *photo,NSDictionary *info,BOOL isDegraded))completion
{
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
            if (downloadFinined && imageData) {
                UIImage *result = [UIImage imageWithData:imageData];
                if (self.shouldFixOrientation) {
                    result = [result fixOrientation];
                }
                BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
                if (completion) completion(imageData,result,info,isDegraded);
            }
        }];
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        ALAsset *alAsset = (ALAsset *)asset;
        ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
        dispatch_globalQueue_async_safe(^{
            CGImageRef originalImageRef = [assetRep fullResolutionImage];
            UIImage *originalImage = [UIImage imageWithCGImage:originalImageRef scale:1.0 orientation:UIImageOrientationUp];
            Byte *imageBuffer = (Byte *)malloc((size_t)assetRep.size);
            NSUInteger bufferSize = [assetRep getBytes:imageBuffer fromOffset:0.0 length:(NSInteger)assetRep.size error:nil];
            NSData *imageData = [NSData dataWithBytesNoCopy:imageBuffer length:bufferSize freeWhenDone:YES];
            dispatch_main_async_safe(^{
                if (completion) completion(imageData,originalImage,nil,NO);
            });
        });
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

/// Judge is a assets array contain the asset 判断一个assets数组是否包含这个asset
- (BOOL)isAssetsArray:(NSArray *)assets containAsset:(id)asset {
    if (iOS8Later) {
        return [assets containsObject:asset];
    } else {
        NSMutableArray *selectedAssetUrls = [NSMutableArray array];
        for (ALAsset *asset_item in assets) {
            [selectedAssetUrls addObject:[asset_item valueForProperty:ALAssetPropertyURLs]];
        }
        return [selectedAssetUrls containsObject:[asset valueForProperty:ALAssetPropertyURLs]];
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

- (LFAssetMediaType)mediaTypeWithModel:(id)asset
{
    LFAssetMediaType type = LFAssetMediaTypePhoto;
    if ([asset isKindOfClass:[PHAsset class]]) {
        PHAsset *phAsset = (PHAsset *)asset;
        if (phAsset.mediaType == PHAssetMediaTypeVideo)      type = LFAssetMediaTypeVideo;
        else if (phAsset.mediaType == PHAssetMediaTypeAudio) type = LFAssetMediaTypeAudio;
    } else if ([asset isKindOfClass:[ALAsset class]]) {
        if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
            type = LFAssetMediaTypeVideo;
        }
    }
    return type;
}

#pragma mark - Private Method

- (LFAlbum *)modelWithResult:(id)result name:(NSString *)name{
    LFAlbum *model = [[LFAlbum alloc] initWithName:name result:result];
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
