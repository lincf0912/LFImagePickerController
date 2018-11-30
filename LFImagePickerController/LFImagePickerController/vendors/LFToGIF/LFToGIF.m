//
//  LFToGIF.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/2.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFToGIF.h"

// Declare constants
#define tmp_fileName     @"_LF_NSGIF.gif"
#define tolerance    @(0.01)

@implementation LFToGIF

#pragma mark - Public methods

+ (void)optimalGIFfromURL:(NSURL*)videoURL loopCount:(int)loopCount completion:(void(^)(NSURL *GifURL))completionBlock {
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *track = [assetVideoTracks firstObject];
    CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    
    float videoWidth = fabs(dimensions.width);
    float videoHeight = fabs(dimensions.height);
    
    LF_GIFSize optimalSize = LF_GIFSizeMedium;
    if (videoWidth >= 1200 || videoHeight >= 1200)
        optimalSize = LF_GIFSizeVeryLow;
    else if (videoWidth >= 800 || videoHeight >= 800)
        optimalSize = LF_GIFSizeLow;
    else if (videoWidth >= 400 || videoHeight >= 400)
        optimalSize = LF_GIFSizeMedium;
    else if (videoWidth < 400|| videoHeight < 400)
        optimalSize = LF_GIFSizeHigh;
    
    [self createGIFfromURL:videoURL delayTime:0 loopCount:loopCount LF_GIFSize:optimalSize completion:completionBlock];
    
}

+ (void)createGIFfromURL:(NSURL*)videoURL delayTime:(NSTimeInterval)delayTime loopCount:(NSUInteger)loopCount LF_GIFSize:(LF_GIFSize)LF_GIFSize completion:(void(^)(NSURL *GifURL))completionBlock {
    
    // Convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    // The frames are spaced evenly over the video, and each has the same duration.
    // delayTime is the amount of time for each frame in the GIF.
    // loopCount is the number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:opts];
    
    // Get the length of the video in seconds
    float videoLength = CMTimeGetSeconds(asset.duration);//asset.duration.value / asset.duration.timescale; // 获取视频总时长,单位秒
    
    /** 限制平均每0.1秒播放一张图片，决定图片大小与流畅度 */
    float framesPerSecond = 0.1f;
    int frameCount = videoLength/framesPerSecond;
    
    // How far along the video track we want to move, in seconds.
    float increment = (float)videoLength/frameCount;
    
    // Add frames to the buffer
    NSMutableArray *timePoints = [NSMutableArray array];
    for (int currentFrame = 0; currentFrame<frameCount; ++currentFrame) {
        float seconds = (float)increment * currentFrame;
        CMTime time = CMTimeMakeWithSeconds(seconds, asset.duration.timescale);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }
    
    // Create properties dictionaries
    NSDictionary *fileProperties = [self filePropertiesWithLoopCount:loopCount];
    NSDictionary *frameProperties = [self framePropertiesWithDelayTime:(delayTime == 0 ? increment : delayTime)];
    
    // Prepare group for firing completion block
    dispatch_group_t gifQueue = dispatch_group_create();
    dispatch_group_enter(gifQueue);
    
    __block NSURL *gifURL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        gifURL = [self createGIFforTimePoints:timePoints fromURL:videoURL fileProperties:fileProperties frameProperties:frameProperties frameCount:frameCount LF_GIFSize:LF_GIFSize];
        
        dispatch_group_leave(gifQueue);
    });
    
    dispatch_group_notify(gifQueue, dispatch_get_main_queue(), ^{
        // Return GIF URL
        completionBlock(gifURL);
    });
    
}

#pragma mark - Base methods

+ (NSURL *)createGIFforTimePoints:(NSArray *)timePoints fromURL:(NSURL *)url fileProperties:(NSDictionary *)fileProperties frameProperties:(NSDictionary *)frameProperties frameCount:(int)frameCount LF_GIFSize:(LF_GIFSize)LF_GIFSize{
    
    NSString *fileName = [[url.lastPathComponent stringByDeletingPathExtension] stringByAppendingString:tmp_fileName];
    NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingString:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath:temporaryFile];
    if (fileURL == nil)
        return nil;
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)fileURL, kUTTypeGIF , frameCount, NULL);
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime tol = CMTimeMakeWithSeconds([tolerance floatValue], asset.duration.timescale);
    generator.requestedTimeToleranceBefore = tol;
    generator.requestedTimeToleranceAfter = tol;
    
    NSError *error = nil;
    CGImageRef previousImageRefCopy = nil;
    for (NSValue *time in timePoints) {
        CGImageRef imageRef;
        
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        imageRef = (float)LF_GIFSize/10 != 1 ? ImageWithScale([generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error], (float)LF_GIFSize/10) : [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
#elif TARGET_OS_MAC
        imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
#endif
        
        if (error) {
            NSLog(@"Error copying image: %@", error);
        }
        if (imageRef) {
            CGImageRelease(previousImageRefCopy);
            previousImageRefCopy = CGImageCreateCopy(imageRef);
        } else if (previousImageRefCopy) {
            imageRef = CGImageCreateCopy(previousImageRefCopy);
        } else {
            NSLog(@"Error copying image and no previous frames to duplicate");
            return nil;
        }
        CGImageDestinationAddImage(destination, imageRef, (CFDictionaryRef)frameProperties);
        CGImageRelease(imageRef);
    }
    CGImageRelease(previousImageRefCopy);
    
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)fileProperties);
    // Finalize the GIF
    if (!CGImageDestinationFinalize(destination)) {
        CFRelease(destination);
        NSLog(@"Failed to finalize GIF destination: %@", error);
        return nil;
    }
    CFRelease(destination);
    
    return fileURL;
}

#pragma mark - Helpers

CGImageRef ImageWithScale(CGImageRef imageRef, float scale) {
    
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    CGSize newSize = CGSizeMake(CGImageGetWidth(imageRef)*scale, CGImageGetHeight(imageRef)*scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    //Release old image
    CFRelease(imageRef);
    // Get the resized image from the context and a UIImage
    imageRef = CGBitmapContextCreateImage(context);
    
    UIGraphicsEndImageContext();
#endif
    
    return imageRef;
}

#pragma mark - Properties

+ (NSDictionary *)filePropertiesWithLoopCount:(NSUInteger)loopCount {
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                 @{(NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)}
             };
}

+ (NSDictionary *)framePropertiesWithDelayTime:(NSTimeInterval)delayTime {
    
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                 @{(NSString *)kCGImagePropertyGIFDelayTime: @(delayTime)},
             (NSString *)kCGImagePropertyColorModel:(NSString *)kCGImagePropertyColorModelRGB
             };
}
@end
