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
- (UIImage *)lf_fastestCompressImageWithSize:(CGFloat)size;
- (UIImage *)lf_fastestCompressImageWithSize:(CGFloat)size imageSize:(NSUInteger)imageSize;
/** 快速压缩 压缩到大约指定体积大小(kb) 返回data, 小于size指定大小，返回nil */
- (NSData *)lf_fastestCompressImageDataWithSize:(CGFloat)size;
- (NSData *)lf_fastestCompressImageDataWithSize:(CGFloat)size imageSize:(NSUInteger)imageSize;

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片(动图) */
- (NSData *)lf_fastestCompressAnimatedImageDataWithScaleRatio:(CGFloat)ratio;
@end
