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
- (void)saveVideoToCustomPhotosAlbumWithTitle:(NSString *)title videoURLs:(NSArray <NSURL *>*)videoURLs complete:(void(^)(id asset, NSError *error))complete;

@end
