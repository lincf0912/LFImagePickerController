//
//  UIImage+LFDecoded.m
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2020/3/5.
//  Copyright © 2020 LamTsanFeng. All rights reserved.
//

#import "UIImage+LFDecoded.h"

@implementation UIImage (LFDecoded)

- (UIImage *)lf_decodedImage
{
    @autoreleasepool {
        CGImageRef imageRef = self.CGImage;
        if (!imageRef) return self;
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        if (width == 0 || height == 0) return self;
        
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef) & kCGBitmapAlphaInfoMask;
        BOOL hasAlpha = NO;
        if (alphaInfo == kCGImageAlphaPremultipliedLast ||
            alphaInfo == kCGImageAlphaPremultipliedFirst ||
            alphaInfo == kCGImageAlphaLast ||
            alphaInfo == kCGImageAlphaFirst) {
            hasAlpha = YES;
        }
        
        // BGRA8888 (premultiplied) or BGRX8888
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, bitmapInfo);
        CGColorSpaceRelease(colorSpace);
        if (!context) return self;
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef); // decode
        CGImageRef newImageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        
        if (!newImageRef) return self;
        UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
        CGImageRelease(newImageRef);
        return newImage;
    }
    
    return self;
}

@end
