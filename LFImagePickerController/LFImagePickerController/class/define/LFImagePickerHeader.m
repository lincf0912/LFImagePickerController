//
//  LFImagePickerHeader.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFImagePickerHeader.h"

NSString *const kBundlePath = @"LFImagePickerController.bundle";

/** 标清图压缩大小 */
float const kCompressSize = 100.f;
/** 缩略图压缩大小 */
float const kThumbnailCompressSize = 10.f;
/** 视频最大时长 */
float const kMaxVideoDurationze = 5*60.f;

NSString *const kImageInfoFileName = @"ImageInfoFileName";     // 图片名称
NSString *const kImageInfoFileSize = @"ImageInfoFileSize";     // 图片大小［长、宽］
NSString *const kImageInfoFileByte = @"ImageInfoFileByte";     // 图片大小［字节］
NSString *const kImageInfoFileOriginalData = @"ImageInfoFileOriginalData";     // 图片数据 原图
NSString *const kImageInfoFileThumbnailData = @"ImageInfoFileThumbnailData";     // 图片数据 缩略图
NSString *const kImageInfoMediaType = @"ImageInfoMediaType";     // 图片类型

@implementation LFImagePickerHeader

@end
