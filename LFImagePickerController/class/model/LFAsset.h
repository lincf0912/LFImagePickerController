//
//  LFAsset.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFAssetMediaType) {
    LFAssetMediaTypePhoto = 0,
    LFAssetMediaTypeLivePhoto,
    LFAssetMediaTypeVideo,
    LFAssetMediaTypeAudio
};

@interface LFAsset : NSObject

@property (nonatomic, readonly) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, assign) BOOL isSelected;      ///< The select status of a photo, default is No
@property (nonatomic, readonly) LFAssetMediaType type;
@property (nonatomic, copy, readonly) NSString *timeLength;

/** 自定义预览图 */
@property (nonatomic, strong) UIImage *previewImage;

/// Init a photo dataModel With a asset
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type;
- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type timeLength:(NSString *)timeLength;

@end
