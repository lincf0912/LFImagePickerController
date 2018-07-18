//
//  LFAsset.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFAssetImageProtocol.h"
#import "LFAssetPhotoProtocol.h"
#import "LFAssetVideoProtocol.h"

typedef NS_ENUM(NSUInteger, LFAssetMediaType) {
    LFAssetMediaTypePhoto = 0,
    LFAssetMediaTypeVideo,
};

typedef NS_ENUM(NSUInteger, LFAssetSubMediaType) {
    LFAssetSubMediaTypeNone = 0,
    
    LFAssetSubMediaTypeGIF = 10,
    LFAssetSubMediaTypeLivePhoto,
};

@interface LFAsset : NSObject

@property (nonatomic, readonly) id asset;             ///< PHAsset or ALAsset
@property (nonatomic, readonly) LFAssetMediaType type;
@property (nonatomic, readonly) LFAssetSubMediaType subType;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, copy, readonly) NSString *name;
/** 关闭livePhoto （ subType = LFAssetSubMediaTypeLivePhoto is work ）default is No */
@property (nonatomic, assign) BOOL closeLivePhoto;


/// Init a photo dataModel With a asset
/// 用一个PHAsset/ALAsset实例，初始化一个照片模型
- (instancetype)initWithAsset:(id)asset;


@end

@interface LFAsset (preview)

/** 自定义缩略图 */
@property (nonatomic, readonly) UIImage *thumbnailImage;
/** 自定义预览图 */
@property (nonatomic, readonly) UIImage *previewImage;
/** 自定义视频URL */
@property (nonatomic, readonly) NSURL *previewVideoUrl;


- (instancetype)initWithImage:(UIImage *)image __deprecated_msg("Method deprecated. Use `initWithObject:`");
- (instancetype)initWithObject:(id/* <LFAssetImageProtocol/LFAssetPhotoProtocol/LFAssetVideoProtocol> */)asset;

@end
