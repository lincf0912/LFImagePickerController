//
//  UIImage+LF_ImageCompress.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/9.
//  Copyright © 2017年 Miracle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LF_ImageCompress)

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)fastestCompressImageWithSize:(CGFloat)size;
/** 快速压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)fastestCompressImageDataWithSize:(CGFloat)size;
@end
