//
//  LFAssetManager.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "LFAlbum.h"
#import "LFAsset.h"


@interface LFAssetManager : NSObject

+ (instancetype)manager NS_SWIFT_NAME(default());
+ (void)free;

/** 缩放值 */
@property (nonatomic, readonly) CGFloat screenScale;

@property (nonatomic, assign) BOOL shouldFixOrientation;

/// 最小可选中的图片宽度，默认是0，小于这个宽度的图片不可选中
@property (nonatomic, assign) NSInteger minPhotoWidthSelectable;
@property (nonatomic, assign) NSInteger minPhotoHeightSelectable;

/** 默认相册对象 */
@property (nonatomic, readonly) ALAssetsLibrary *assetLibrary;

/**
 *  @author lincf, 16-07-28 17:07:38
 *
 *  Get Album 获得相册/相册数组
 *
 *  @param allowPickingVideo 是否包含视频
 *  @param allowPickingImage 是否包含相片
 *  @param fetchLimit        相片最大数量（IOS8之后有效）
 *  @param ascending         顺序获取（IOS8之后有效）
 *  @param completion        回调结果
 */
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(LFAlbum *model))completion;


/**
 Get Album 获得相册/相册数组

 @param allowPickingVideo 是否包含视频
 @param allowPickingImage 是否包含相片
 @param ascending 顺序获取（IOS8之后有效）
 @param completion 回调结果
 */
- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage ascending:(BOOL)ascending completion:(void (^)(NSArray<LFAlbum *> *))completion;

/**
 *  @author lincf, 16-07-28 13:07:27
 *
 *  Get Assets 获得Asset数组
 *
 *  @param result            LFAlbum.result
 *  @param allowPickingVideo 是否包含视频
 *  @param allowPickingImage 是否包含相片
 *  @param fetchLimit        相片最大数量
 *  @param ascending         顺序获取
 *  @param completion        回调结果
 */
- (void)getAssetsFromFetchResult:(id)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage fetchLimit:(NSInteger)fetchLimit ascending:(BOOL)ascending completion:(void (^)(NSArray<LFAsset *> *models))completion;
/** 获得下标为index的单个照片 */
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(LFAsset *model))completion;

/// Get photo 获得照片
- (void)getPostImageWithAlbumModel:(LFAlbum *)model ascending:(BOOL)ascending completion:(void (^)(UIImage *postImage))completion;

- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;
- (PHImageRequestID)getPhotoWithAsset:(id)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed;
- (PHImageRequestID)getPhotoWithAsset:(id)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed;

/**
 *  通过asset解析缩略图、标清图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、标清图、图片数据字典
 */
- (void)getPreviewPhotoWithAsset:(id)asset completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion;
/**
 *  通过asset解析缩略图、原图、图片数据字典
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 返回block 顺序：缩略图、原图、图片数据字典
 */
- (void)getOriginPhotoWithAsset:(id)asset completion:(void (^)(UIImage *thumbnail, UIImage *source, NSDictionary *info))completion;

/**
 *  @author lincf, 16-06-15 13:06:26
 *
 *  视频压缩并缓存压缩后视频 (将视频格式变为mp4)
 *
 *  @param asset      PHAsset／ALAsset
 *  @param completion 回调压缩后视频路径，可以复制或剪切
 */
- (void)compressAndCacheVideoWithAsset:(id)asset completion:(void (^)(NSString *path))completion;


/// Get full Image 获取原图
/// 该方法会先返回缩略图，再返回原图，如果info[PHImageResultIsDegradedKey] 为 YES，则表明当前返回的是缩略图，否则是原图。
- (void)getOriginalPhotoWithAsset:(id)asset completion:(void (^)(NSData *data, UIImage *photo,NSDictionary *info,BOOL isDegraded))completion;

/// Get video 获得视频
- (void)getVideoWithAsset:(id)asset completion:(void (^)(AVPlayerItem * playerItem, NSDictionary * info))completion;

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray <LFAsset *>*)photos completion:(void (^)(NSString *totalBytes))completion;

/// Judge is a assets array contain the asset 判断一个assets数组是否包含这个asset
- (BOOL)isAssetsArray:(NSArray *)assets containAsset:(id)asset;

- (NSString *)getAssetIdentifier:(id)asset;
- (BOOL)isCameraRollAlbum:(NSString *)albumName;

/// 检查照片大小是否满足最小要求
- (BOOL)isPhotoSelectableWithAsset:(id)asset;
- (CGSize)photoSizeWithAsset:(id)asset;

/** 对象媒体类型 */
- (LFAssetMediaType)mediaTypeWithModel:(id)asset;

/// Return Cache Path 返回压缩缓存视频路径
+ (NSString *)CacheVideoPath;

/** 清空视频缓存 */
+ (BOOL)cleanCacheVideoPath;

- (NSURL *)getURLInPlayer:(AVPlayer *)player;

@end
