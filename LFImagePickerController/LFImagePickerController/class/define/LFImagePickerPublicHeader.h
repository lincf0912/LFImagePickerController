//
//  LFImagePickerPublicHeader.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/1.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifndef LFImagePickerPublicHeader_h
#define LFImagePickerPublicHeader_h

typedef NSString * kImageInfoFileKey NS_STRING_ENUM;

/**
 *  NSString;
 */
extern kImageInfoFileKey const kImageInfoFileName __deprecated_msg("enum type deprecated. Use `LFReusltInfo`");     // 图片名称
/**
 *  NSValue; CGSize size;[value getValue:&size];
 */
extern kImageInfoFileKey const kImageInfoFileSize __deprecated_msg("enum type deprecated. Use `LFReusltInfo`");     // 图片大小［长、宽］
/**
 *  NSNumber(CGFloat);
 */
extern kImageInfoFileKey const kImageInfoFileByte __deprecated_msg("enum type deprecated. Use `LFReusltInfo`");     // 图片大小［字节］
/**
 *  NSData;
 */
extern kImageInfoFileKey const kImageInfoFileOriginalData __deprecated_msg("enum type deprecated. Use `LFReusltImage`");     // 图片数据 原图
extern kImageInfoFileKey const kImageInfoFileThumbnailData __deprecated_msg("enum type deprecated. Use `LFReusltImage`");     // 图片数据 缩略图
/**
 *  NSNumber(NSUInteger) -> LFImagePickerSubMediaType;
 */
extern kImageInfoFileKey const kImageInfoMediaType __deprecated_msg("enum type deprecated. Use `LFReusltImage`");     // 图片类型


typedef NS_ENUM(NSUInteger, LFImagePickerSubMediaType) {
    LFImagePickerSubMediaTypeNone = 0,
    
    LFImagePickerSubMediaTypeGIF = 10,
    LFImagePickerSubMediaTypeLivePhoto,
};

typedef NS_ENUM(NSUInteger, LFPickingMediaType) {
    /** None */
    LFPickingMediaTypeNone = 0,
    /** Whether the user can picking a photo */
    LFPickingMediaTypePhoto = 1 << 0,
    /** Whether the user can picking a gif */
    LFPickingMediaTypeGif = 1 << 1,
    /** Whether the user can picking a livePhoto(gif) */
    LFPickingMediaTypeLivePhoto = 1 << 2,
    /** Whether the user can picking a video */
    LFPickingMediaTypeVideo = 1 << 3,
    /** Users can picking all media types */
    LFPickingMediaTypeALL = ~0UL,
};


#endif /* LFImagePickerPublicHeader_h */
