//
//  LFAssetManager+Simple.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2019/9/26.
//  Copyright © 2019 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LFAssetManager (Simple)

/** 排序 YES */
@property (nonatomic, assign) BOOL sortAscendingByCreateDate;
/** 类型 LFPickingMediaTypeALL */
@property (nonatomic, assign) LFPickingMediaType allowPickingType;

/**
 *  @author lincf, 16-07-28 17:07:38
 *
 *  Get Album 获得相机胶卷相册
 *
 *  @param fetchLimit        相片最大数量（IOS8之后有效）
 *  @param completion        回调结果
 */
- (void)getCameraRollAlbumFetchLimit:(NSInteger)fetchLimit completion:(void (^)(LFAlbum *model))completion;


/**
 Get Album 获得所有相册/相册数组

 @param completion 回调结果
 */
- (void)getAllAlbums:(void (^)(NSArray<LFAlbum *> *))completion;

/**
 *  @author lincf, 16-07-28 13:07:27
 *
 *  Get Assets 获得Asset数组
 *
 *  @param result            LFAlbum.result 相册对象
 *  @param fetchLimit        相片最大数量
 *  @param completion        回调结果
 */
- (void)getAssetsFromFetchResult:(id)result fetchLimit:(NSInteger)fetchLimit completion:(void (^)(NSArray<LFAsset *> *models))completion;

/** 获得下标为index的单个照片 */
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index completion:(void (^)(LFAsset *))completion;

/// Get photo 获得照片
- (void)getPostImageWithAlbumModel:(LFAlbum *)model completion:(void (^)(UIImage *postImage))completion;

@end

NS_ASSUME_NONNULL_END
