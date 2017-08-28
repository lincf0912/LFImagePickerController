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

typedef NS_ENUM(NSUInteger, LFEditPhotoOperation) {
    /** 绘画 */
    LFEditPhotoOperation_draw = 1 << 0,
    /** 贴图 */
    LFEditPhotoOperation_sticker = 1 << 1,
    /** 文本 */
    LFEditPhotoOperation_text = 1 << 2,
    /** 模糊 */
    LFEditPhotoOperation_splash = 1 << 3,
    /** 修剪 */
    LFEditPhotoOperation_crop = 1 << 4,
    /** 所有 */
    LFEditPhotoOperation_All = ~0UL,
};

typedef NS_ENUM(NSUInteger, LFEditVideoOperation) {
    /** 绘画 */
    LFEditVideoOperation_draw = 1 << 0,
    /** 贴图 */
    LFEditVideoOperation_sticker = 1 << 1,
    /** 文本 */
    LFEditVideoOperation_text = 1 << 2,
    /** 音频 */
    LFEditVideoOperation_audio = 1 << 3,
    /** 剪辑 */
    LFEditVideoOperation_clip = 1 << 4,
    /** 所有 */
    LFEditVideoOperation_All = ~0UL,
};
#endif /* LFImagePickerPublicHeader_h */
