//
//  LFAlbum.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LFAsset;
@interface LFAlbum : NSObject

@property (nonatomic, readonly) NSString *name;        ///< The album name
@property (nonatomic, readonly) NSInteger count;       ///< Count of photos the album contain
@property (nonatomic, readonly) id result;             ///< PHFetchResult<PHAsset> or ALAssetsGroup<ALAsset>
@property (nonatomic, readonly) id album NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;             /// PHAssetCollection
@property (nonatomic, strong) LFAsset *posterAsset;    /** 封面对象 */

/** 缓存数据 */
@property (nonatomic, strong) NSArray <LFAsset *>*models;

- (instancetype)initWithAlbum:(id)album result:(id)result;


- (void)changedAlbum:(id /*PHAssetCollection*/)album NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;
- (void)changedResult:(id /*PHFetchResult*/)result NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;

@end
