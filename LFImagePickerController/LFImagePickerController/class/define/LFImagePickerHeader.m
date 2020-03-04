//
//  LFImagePickerHeader.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFImagePickerHeader.h"

/** 视频时间（取整：四舍五入） */
NSTimeInterval lf_videoDuration(NSTimeInterval duration)
{
    return (NSInteger)(duration+0.5f)*1.f;
}

BOOL lf_isPiiic(CGSize imageSize)
{
    if (imageSize.height >= [UIScreen mainScreen].bounds.size.height) {
        return imageSize.width * 2 < imageSize.height;
    }
    return imageSize.width * 3 < imageSize.height;
}

BOOL lf_isHor(CGSize imageSize)
{
    if (imageSize.width >= [UIScreen mainScreen].bounds.size.width) {
        return imageSize.width > imageSize.height * 2;
    }
    return imageSize.width > imageSize.height * 3;
}


/** 标清图压缩大小 */
float const kCompressSize = 100.f;
/** 缩略图压缩大小 */
float const kThumbnailCompressSize = 10.f;
/** 图片最大大小 */
float const kMaxPhotoBytes = 6*1024*1024.f;
/** 视频最大时长 */
float const kMaxVideoDurationze = 5*60.f;

NSString *const kImageInfoFileName = @"ImageInfoFileName";     // 图片名称
NSString *const kImageInfoFileSize = @"ImageInfoFileSize";     // 图片大小［长、宽］
NSString *const kImageInfoFileByte = @"ImageInfoFileByte";     // 图片大小［字节］
NSString *const kImageInfoFileOriginalData = @"ImageInfoFileOriginalData";     // 图片数据 原图
NSString *const kImageInfoFileThumbnailData = @"ImageInfoFileThumbnailData";     // 图片数据 缩略图
NSString *const kImageInfoMediaType = @"ImageInfoMediaType";     // 图片类型

