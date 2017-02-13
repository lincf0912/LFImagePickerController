//
//  LFAsset.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LFAssetMediaType) {
    LFAssetMediaTypePhoto = 0,
    LFAssetMediaTypeLivePhoto,
    LFAssetMediaTypeVideo,
    LFAssetMediaTypeAudio
};

@interface LFAsset : NSObject

@property (nonatomic, strong) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, assign) LFAssetMediaType type;
@property (nonatomic, copy) NSString *timeLength;

/// Init a photo dataModel With a asset
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
+ (instancetype)modelWithAsset:(id)asset type:(LFAssetMediaType)type;
+ (instancetype)modelWithAsset:(id)asset type:(LFAssetMediaType)type timeLength:(NSString *)timeLength;

@end
