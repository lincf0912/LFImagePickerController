//
//  LFAssetManager+SaveAlbum.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"

@interface LFAssetManager (SaveAlbum)

/** 保存图片到自定义相册 */
- (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title images:(NSArray <UIImage *>*)images complete:(void (^)(NSArray <id /* PHAsset/ALAsset */>*assets,NSError *error))complete;
- (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title imageDatas:(NSArray <NSData *>*)imageDatas complete:(void (^)(NSArray <id /* PHAsset/ALAsset */>*assets ,NSError *error))complete;

/** 保存视频到自定义相册 */
- (void)saveVideoToCustomPhotosAlbumWithTitle:(NSString *)title videoURLs:(NSArray <NSURL *>*)videoURLs complete:(void(^)(NSArray <id /* PHAsset/ALAsset */>*assets, NSError *error))complete;

/** 删除相册中的媒体文件 */
- (void)deleteAssets:(NSArray <id /* PHAsset/ALAsset */ > *)assets complete:(void (^)(NSError *error))complete;

/** 删除相册 */
- (void)deleteAssetCollections:(NSArray <PHAssetCollection *> *)collections complete:(void (^)(NSError *error))complete NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;
- (void)deleteAssetCollections:(NSArray <PHAssetCollection *> *)collections deleteAssets:(BOOL)deleteAssets complete:(void (^)(NSError *error))complete NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;

@end
