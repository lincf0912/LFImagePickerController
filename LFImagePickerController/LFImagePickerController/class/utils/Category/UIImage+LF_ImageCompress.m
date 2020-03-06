//
//  UIImage+LF_ImageCompress.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/9.
//  Copyright © 2017年 Miracle. All rights reserved.
//

#import "UIImage+LF_ImageCompress.h"
#import "LFGIFImageSerialization.h"

@implementation UIImage (LF_ImageCompress)

/** 快速压缩 压缩到大约指定体积大小(kb) 返回压缩后图片 */
- (UIImage *)lf_fastestCompressImageWithSize:(CGFloat)size
{
    return [self lf_fastestCompressImageWithSize:size imageSize:0];
}

- (UIImage *)lf_fastestCompressImageWithSize:(CGFloat)size imageSize:(NSUInteger)imageSize
{
    NSData *imageData = [self lf_fastestCompressImageSize:size imageSize:imageSize];
    UIImage *compressedImage = nil;
    if (imageData) {
        compressedImage = [UIImage imageWithData:imageData scale:self.scale];
    }
    if (!compressedImage) {
        return self;
    }
    return compressedImage;
}

/** 快速压缩 压缩到大约指定体积大小(kb) 返回data */
- (NSData *)lf_fastestCompressImageDataWithSize:(CGFloat)size
{
    return [self lf_fastestCompressImageDataWithSize:size imageSize:0];
}

- (NSData *)lf_fastestCompressImageDataWithSize:(CGFloat)size imageSize:(NSUInteger)imageSize
{
    return [self lf_fastestCompressImageSize:size imageSize:imageSize];
}

#pragma mark - 压缩图片接口
- (NSData *)lf_fastestCompressImageSize:(CGFloat)size imageSize:(NSUInteger)imageSize
{
    @autoreleasepool {
        
        /** 临时图片 */
        UIImage *compressedImage = self;
        CGFloat targetSize = size * 1024; // 压缩目标大小
        CGFloat defaultPercent = 0.65f; // 压缩系数
        CGFloat percent = defaultPercent;
        /** 微调参数 */
        NSInteger microAdjustment = 8*1024;
        /** 设备分辨率 */
        CGSize pixel = [UIImage lf_appPixel];
        /** 缩放图片尺寸 */
        int MIN_UPLOAD_RESOLUTION = pixel.width * pixel.height;
        /** 当前图片尺寸 */
        float currentResolution = self.size.height * self.size.width;
        /** 偏移量 */
        float offsetSize = size * 0.2 * 1024;
        
        /** 图片大小 */
        long long imageLength = imageSize;
        NSData *imageData = nil;
        
        if (imageLength == 0) {
            imageData = LF_UIImageJPEGRepresentation(self, 1);
            imageLength = imageData.length;
            /** 没有需要压缩的必要，直接返回 */
            if (imageLength <= targetSize) return nil;
        } else {
            /** 没有需要压缩的必要，直接返回 */
            if (imageLength <= targetSize) return nil;
        }
        
        /** 缩放图片 */
        if (currentResolution > MIN_UPLOAD_RESOLUTION) {
            float factor = sqrt(currentResolution / MIN_UPLOAD_RESOLUTION) * 2;
            compressedImage = [self lf_scaleWithSize:CGSizeMake(self.size.width / factor, self.size.height / factor)];
        }
        
        percent *= (targetSize/imageLength);
        
        
        /** 记录上一次的压缩大小 */
        NSInteger imageDatalength = 0;
        
        //    int index = 0;
        
        /** 压缩核心方法 */
        do {
            
            //        NSLog(@"compress %d", index++);
            
            imageData = LF_UIImageJPEGRepresentation(compressedImage, percent);
            
            //        NSLog(@"压缩后大小:%ldk, 压缩频率:%ldk", imageData.length/1024, (imageDatalength - imageData.length)/1024);
            
            CGFloat diffSize = imageData.length - targetSize;
            
            if (diffSize > targetSize/3) { /** 压缩后与期望值相差超过1/3 */
                percent -=.2f;
            } else if (diffSize < microAdjustment) { // 压缩精确度调整
                percent -= .02f; // 微调
            } else {
                percent -= .1f;
            }
            
            if (percent < 0.01) {
                /** 压缩系数不能少于0 */
                percent = 0.1;
            }
            
            // 大小没有改变 & 压缩后大小可能会微略变大的情况
            if (imageDatalength > 0 && imageData.length >= imageDatalength) {
                // 压缩大小没有改变，需要调整图片尺寸
                float scale = (targetSize/diffSize);
                if (scale < .5f) scale = 0.5f;
                if (scale > .85f) scale = 0.85f;
                compressedImage = [self lf_scaleWithSize:CGSizeMake(compressedImage.size.width * scale, compressedImage.size.height * scale)];
            }
            imageDatalength = imageData.length;
        } while (imageData.length > targetSize+offsetSize);/** 增加偏移量 */
        
        return imageData;
    }
}

/** 快速压缩 压缩到大约指定体积缩放 返回压缩后图片(动图) */
- (NSData *)lf_fastestCompressAnimatedImageDataWithScaleRatio:(CGFloat)ratio
{
    @autoreleasepool {    
        if (self.images.count == 0) return nil;
        
        NSMutableArray *images = [@[] mutableCopy];
        
        CGSize imageSize = CGSizeMake(self.size.width*ratio, self.size.height*ratio);
        for (UIImage *subImage in self.images) {
            UIImage *compressImage = [subImage lf_scaleWithSize:imageSize];
            [images addObject:compressImage];
        }
        
        UIImage *aminatedImage = [UIImage animatedImageWithImages:images duration:self.duration];
        
        return LF_UIImageGIFRepresentation(aminatedImage);
    }
}



#pragma mark - 缩放图片尺寸
- (UIImage*)lf_scaleWithSize:(CGSize)newSize
{
    
    if (newSize.width*newSize.height > self.size.width*self.size.height) {
        return self;
    }
    //We prepare a bitmap with the new size
    UIGraphicsBeginImageContextWithOptions(newSize, NO, self.scale);
    
    //Draws a rect for the image
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    //We set the scaled image from the context
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

/** 设备分辨率 */
+ (CGSize)lf_appPixel
{
    CGRect rect_screen = [[UIScreen mainScreen]bounds];
    CGSize size_screen = rect_screen.size;
    
    CGFloat scale_screen = 1.0;//[UIScreen mainScreen].scale;
    
    CGFloat width = size_screen.width*scale_screen;
    CGFloat height = size_screen.height*scale_screen;
    
    return CGSizeMake(width, height);
}
@end
