//
//  LFAssetManager+Simple.m
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2019/9/26.
//  Copyright © 2019 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager+Simple.h"

@implementation LFAssetManager (Simple)

@dynamic sortAscendingByCreateDate, allowPickingType;

- (BOOL)sortAscendingByCreateDate_iOS8
{
    /** 倒序情况下。iOS8的result已支持倒序,这里的排序应该为顺序 */
    BOOL ascending = self.sortAscendingByCreateDate;
    if (@available(iOS 8.0, *)){
        if (!self.sortAscendingByCreateDate) {
            ascending = !self.sortAscendingByCreateDate;
        }
    }
    return ascending;
}

/**
 *  @author lincf, 16-07-28 17:07:38
 *
 *  Get Album 获得相机胶卷相册
 *
 *  @param fetchLimit        相片最大数量（IOS8之后有效）
 *  @param completion        回调结果
 */
- (void)getCameraRollAlbumFetchLimit:(NSInteger)fetchLimit completion:(void (^)(LFAlbum *model))completion
{
    [self getCameraRollAlbum:self.allowPickingType fetchLimit:fetchLimit ascending:self.sortAscendingByCreateDate_iOS8 completion:completion];
}


/**
 Get Album 获得所有相册/相册数组

 @param completion 回调结果
 */
- (void)getAllAlbums:(void (^)(NSArray<LFAlbum *> *))completion
{
    [self getAllAlbums:self.allowPickingType ascending:self.sortAscendingByCreateDate_iOS8 completion:completion];
}

/**
 *  @author lincf, 16-07-28 13:07:27
 *
 *  Get Assets 获得Asset数组
 *
 *  @param result            LFAlbum.result 相册对象
 *  @param fetchLimit        相片最大数量
 *  @param completion        回调结果
 */
- (void)getAssetsFromFetchResult:(id)result fetchLimit:(NSInteger)fetchLimit completion:(void (^)(NSArray<LFAsset *> *models))completion
{
    [self getAssetsFromFetchResult:result allowPickingType:self.allowPickingType fetchLimit:fetchLimit ascending:self.sortAscendingByCreateDate_iOS8 completion:completion];
}

/** 获得下标为index的单个照片 */
- (void)getAssetFromFetchResult:(id)result atIndex:(NSInteger)index completion:(void (^)(LFAsset *))completion
{
    [self getAssetFromFetchResult:result atIndex:index allowPickingType:self.allowPickingType ascending:self.sortAscendingByCreateDate_iOS8 completion:completion];
}

/// Get photo 获得照片
- (void)getPostImageWithAlbumModel:(LFAlbum *)model completion:(void (^)(UIImage *postImage))completion
{
    [self getPostImageWithAlbumModel:model ascending:self.sortAscendingByCreateDate_iOS8 completion:completion];
}
@end
