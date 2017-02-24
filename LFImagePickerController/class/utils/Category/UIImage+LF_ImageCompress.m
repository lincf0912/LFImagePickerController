//
//  UIImage+LF_ImageCompress.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/9.
//  Copyright © 2017年 Miracle. All rights reserved.
//

#import "UIImage+LF_ImageCompress.h"

@implementation UIImage (LF_ImageCompress)

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)fastestCompressImageWithSize:(CGFloat)size
{
    UIImage *compressedImage = [UIImage imageWithData:[self fastestCompressImageSize:size]];
    if (!compressedImage) {
        return self;
    }
    return compressedImage;
}

/** 快速压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)fastestCompressImageDataWithSize:(CGFloat)size
{
    return [self fastestCompressImageSize:size];
}

#pragma mark - 压缩图片接口
- (NSData *)fastestCompressImageSize:(CGFloat)size
{
    /** 临时图片 */
    UIImage *compressedImage = self;
    CGFloat targetSize = size * 1024; // 压缩目标大小
    CGFloat percent = 0.5f; // 压缩系数
    if (size <= 10) {
        percent = 0.01;
    }
    /** 微调参数 */
    NSInteger microAdjustment = 5*1024;
    /** 设备分辨率 */
    CGSize pixel = [UIImage appPixel];
    /** 缩放图片尺寸 */
    int MIN_UPLOAD_RESOLUTION = pixel.width * pixel.height;
    if (size < 100) {
        MIN_UPLOAD_RESOLUTION /= 2;
    }
    /** 缩放比例 */
    float factor;
    /** 当前图片尺寸 */
    float currentResolution = self.size.height * self.size.width;
    
    NSData *imageData = UIImageJPEGRepresentation(self, 1);
    
    /** 没有需要压缩的必要，直接返回 */
    if (imageData.length <= targetSize) return imageData;
    
    /** 缩放图片 */
    if (currentResolution > MIN_UPLOAD_RESOLUTION) {
        factor = sqrt(currentResolution / MIN_UPLOAD_RESOLUTION) * 2;
        compressedImage = [self scaleWithSize:CGSizeMake(self.size.width / factor, self.size.height / factor)];
    }
    
    /** 记录上一次的压缩大小 */
    NSInteger imageDatalength = 0;
    
    /** 压缩核心方法 */
    do {
        if (percent < 0.01) {
            /** 压缩系数不能少于0 */
            percent = 0.1f;
        }
        imageData = UIImageJPEGRepresentation(compressedImage, percent);
        
        //        NSLog(@"压缩后大小:%ldk, 压缩频率:%ldk", imageData.length/1024, (imageDatalength - imageData.length)/1024);
        // 压缩精确度调整
        if (imageData.length - targetSize < microAdjustment) {
            percent -= .02f; // 微调
        } else {
            percent -= .1f;
        }
        
        // 大小没有改变
        if (imageData.length == imageDatalength) {
            //            NSLog(@"压缩大小没有改变，需要调整图片尺寸");
            //            break;
            float scale = targetSize/(imageData.length-targetSize);
            /** 精准缩放计算误差值 */
            float gap = targetSize/(imageData.length/2-targetSize);
            gap = gap >= 1.0f || gap <= 0 ? 0.85f : gap;
            scale *= gap;
            if (scale >= 1.0f || scale <= 0) scale = 0.85f;
            compressedImage = [self scaleWithSize:CGSizeMake(compressedImage.size.width * scale, compressedImage.size.height * scale)];
        }
        imageDatalength = imageData.length;
    } while (imageData.length > targetSize+1024);/** 增加1k偏移量 */
    
    return imageData;
}

#pragma mark - 缩放图片尺寸
- (UIImage*)scaleWithSize:(CGSize)newSize
{
    
    //We prepare a bitmap with the new size
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0.0);
    
    //Draws a rect for the image
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    //We set the scaled image from the context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

/** 设备分辨率 */
+ (CGSize)appPixel
{
    CGRect rect_screen = [[UIScreen mainScreen]bounds];
    CGSize size_screen = rect_screen.size;
    
    CGFloat scale_screen = [UIScreen mainScreen].scale;
    
    CGFloat width = size_screen.width*scale_screen;
    CGFloat height = size_screen.height*scale_screen;
    
    return CGSizeMake(width, height);
}
@end
