//
//  LFImagePickerHeader.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFImagePickerHeader.h"

NSString *const kBundlePath = @"LFImagePickerController.bundle";
/** 编辑资源路径 */
NSString *const kEditPath = @"LFImagePickerController.bundle/editImage";
/** 贴图资源路径 */
NSString *const kStickersPath = @"LFImagePickerController.bundle/editImage/stickers";

/** 标清图压缩大小 */
CGFloat const kCompressSize = 100.f;
/** 缩略图压缩大小 */
CGFloat const kThumbnailCompressSize = 10.f;

NSString *const kImageInfoFileName = @"ImageInfoFileName";     // 图片名称
NSString *const kImageInfoFileSize = @"ImageInfoFileSize";     // 图片大小［长、宽］
NSString *const kImageInfoFileByte = @"ImageInfoFileByte";     // 图片大小［字节］
NSString *const kImageInfoFileData = @"ImageInfoFileData";     // 图片数据

@implementation LFImagePickerHeader

@end
