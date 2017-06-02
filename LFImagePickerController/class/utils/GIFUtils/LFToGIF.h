//
//  LFToGIF.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/2.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <CoreServices/CoreServices.h>
#import <WebKit/WebKit.h>
#endif

typedef NS_ENUM(NSInteger, LF_GIFSize) {
    LF_GIFSizeVeryLow  = 2,
    LF_GIFSizeLow      = 3,
    LF_GIFSizeMedium   = 5,
    LF_GIFSizeHigh     = 7,
    LF_GIFSizeOriginal = 10
};

@interface LFToGIF : NSObject


/**
 解析视频转换为GIF图片

 @param videoURL 视频地址
 @param loopCount 循环次数 0=无限循环
 @param completionBlock 回调gif地址
 */
+ (void)optimalGIFfromURL:(NSURL*)videoURL loopCount:(int)loopCount completion:(void(^)(NSURL *GifURL))completionBlock;

/**
 解析视频转换为GIF图片

 @param videoURL 视频地址
 @param delayTime 每张图片的停留时间
 @param loopCount 循环次数 0=无限循环
 @param LF_GIFSize gif图片质量
 @param completionBlock 回调gif地址
 */
+ (void)createGIFfromURL:(NSURL*)videoURL delayTime:(NSTimeInterval)delayTime loopCount:(NSUInteger)loopCount LF_GIFSize:(LF_GIFSize)LF_GIFSize completion:(void(^)(NSURL *GifURL))completionBlock;
@end
