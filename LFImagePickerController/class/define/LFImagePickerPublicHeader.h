//
//  LFImagePickerPublicHeader.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/1.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifndef LFImagePickerPublicHeader_h
#define LFImagePickerPublicHeader_h

/**
 *  NSString;
 */
extern NSString *const kImageInfoFileName;     // 图片名称
/**
 *  NSValue; CGSize size;[value getValue:&size];
 */
extern NSString *const kImageInfoFileSize;     // 图片大小［长、宽］
/**
 *  NSNumber(CGFloat);
 */
extern NSString *const kImageInfoFileByte;     // 图片大小［字节］
/**
 *  NSData;
 */
extern NSString *const kImageInfoFileOriginalData;     // 图片数据 原图
extern NSString *const kImageInfoFileThumbnailData;     // 图片数据 缩略图
/**
 *  NSNumber(NSUInteger) -> LFImagePickerSubMediaType;
 */
extern NSString *const kImageInfoMediaType;     // 图片类型


typedef NS_ENUM(NSUInteger, LFImagePickerSubMediaType) {
    LFImagePickerSubMediaTypeNone = 0,
    
    LFImagePickerSubMediaTypeGIF = 10,
    LFImagePickerSubMediaTypeLivePhoto,
};

#endif /* LFImagePickerPublicHeader_h */
