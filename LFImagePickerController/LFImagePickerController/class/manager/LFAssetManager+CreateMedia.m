//
//  LFAssetManager+CreateMedia.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/9/5.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager+CreateMedia.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIImage+LF_Format.h"
#import "UIImage+LFCommon.h"

NSString *const CreateMediaFolder = @"LFAssetManager.CreateMedia";

@implementation LFAssetManager (CreateMedia)

- (NSString *)myMediaFolder
{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *path = [tmpDir stringByAppendingPathComponent:CreateMediaFolder];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:path];
    if (isExists == NO) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images size:(CGSize)size duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error
{
    NSMutableArray <UIImage *>*newImages = [@[] mutableCopy];
    for (UIImage *image in images) {
        UIImage *newImage = [image lf_scaleToSize:size];
        [newImages addObject:newImage];
    }
    return [self createGifDataWithImages:newImages duration:duration loopCount:loopCount error:error];
}

- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error
{
    if (images.count == 0) return nil;
    
    NSDictionary *userInfo = nil;
    {
        size_t frameCount = images.count;
        NSTimeInterval frameDuration = (duration / frameCount);
        NSDictionary *frameProperties = @{
                                          (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                  (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDuration)
                                                  }
                                          };
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
        
        NSDictionary *imageProperties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                   (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)
                                                   }
                                           };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
        
        for (size_t idx = 0; idx < images.count; idx++) {
            CGImageDestinationAddImage(destination, [[images objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            if (error) {
                *error = [[NSError alloc] initWithDomain:@"LFAssetManager.CreateMedia.gif.error" code:-1 userInfo:userInfo];                
            }
            return nil;
        }
        
        return [NSData dataWithData:mutableData];
    }
}

- (UIImage *)createGifWithImages:(NSArray <UIImage *>*)images size:(CGSize)size duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error
{
    UIImage *image = nil;
    NSData *imageData = [self createGifDataWithImages:images size:size duration:duration loopCount:loopCount error:error];
    if (imageData) {
        image = [UIImage LF_imageWithImageData:imageData];
    }
    return image;
}

- (UIImage *)createGifWithImages:(NSArray <UIImage *>*)images duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error
{
    UIImage *image = nil;
    NSData *imageData = [self createGifDataWithImages:images duration:duration loopCount:loopCount error:error];
    if (imageData) {
        image = [UIImage LF_imageWithImageData:imageData];
    }
    return image;
}

- (void)createMP4WithImages:(NSArray <UIImage *>*)images size:(CGSize)size fps:(NSUInteger)fps duration:(NSTimeInterval)duration audioPath:(NSString *)audioPath complete:(void (^)(NSData *data, NSError *error))complete
{
    /** 视频的宽高都必须是16的整数倍,否则经过AVFoundation的API合成后系统会自动对尺寸进行校正，不足的地方会以绿边的形式进行填充 */
    CGFloat v_w = round(size.width/16.f)*16.f;
    CGFloat v_h = round(size.height/16.f)*16.f;
    size = CGSizeMake(v_w, v_h);
    
    NSMutableArray <UIImage *>*newImages = [@[] mutableCopy];
    for (UIImage *image in images) {
        UIImage *newImage = [image lf_scaleToSize:size];
        [newImages addObject:newImage];
    }
    
    NSString *videoOutputPath = [[self myMediaFolder] stringByAppendingPathComponent:@"lf_createMedia_mp4.mp4"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoOutputPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:videoOutputPath error:nil];
    }
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:size.width], AVVideoWidthKey, [NSNumber numberWithInt:size.height],  AVVideoHeightKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    AVAssetWriterInputPixelBufferAdaptor *adaptor =  [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    
    NSParameterAssert(videoWriterInput);
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    // 生成video writer
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:videoOutputPath] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    // 将video的设置绑定到video writer中
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    // 计算帧数
    int frameCount = 0;
    double numberOfSecondsPerFrame = duration / newImages.count;
    double frameDuration = fps * numberOfSecondsPerFrame;
    
    CVPixelBufferRef buffer = NULL;
    
    // Convert uiimage to CGImage.
    for(UIImage * img in newImages)
    {
        buffer = [self newPixelBufferFromCGImage:[img CGImage]];
        
        if (buffer == nil) {
            continue;
        }
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < fps)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                // 将每一帧图片生成的buffer添加到视频相应的位置
                
                //print out status:
                NSLog(@"Processing video frame (%d, %lu)", frameCount, (unsigned long)[newImages count]);
                
                // CMTimeMake(a,b)    a当前第几帧, b每秒钟多少帧.当前播放时间a/b
                CMTime frameTime = CMTimeMake(frameCount * frameDuration, (int32_t) fps);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                if(!append_ok)
                {
                    NSError *error = videoWriter.error;
                    if (error!=nil)
                    {
                        NSLog(@"Unresolved error %@,%@.", error, [error userInfo]);
                    }
                }
            }
            else
            {
                // 现在还不能添加，进行等待
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        
        if (!append_ok)
        {
            // 添加失败，记录log
            printf("error appending image %d times %d\n, with error.", frameCount, j);
        }
        
        // 增加frame计数
        frameCount++;
        CVPixelBufferRelease(buffer);
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoWriter.error == nil && audioPath.length) {
                [self mixVideo:videoOutputPath audio:audioPath complete:^(NSData *data, NSError *error) {
                    if (complete) complete(data, error);
                }];
            } else {
                NSData *data = [NSData dataWithContentsOfFile:videoOutputPath];
                if (complete) complete(data, videoWriter.error);
            }
        });
    }];
}

- (void)createMP4WithImages:(NSArray <UIImage *>*)images size:(CGSize)size audioPath:(NSString *)audioPath complete:(void (^)(NSData *data, NSError *error))complete
{
    [self createMP4WithImages:images size:size fps:30 duration:images.count audioPath:audioPath complete:complete];
}

- (void)createMP4WithImages:(NSArray <UIImage *>*)images size:(CGSize)size complete:(void (^)(NSData *data, NSError *error))complete
{
    [self createMP4WithImages:images size:size audioPath:nil complete:complete];
}

#pragma mark - 基础函数

// CGImage to CVPixelBufferRef
- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    if (status == kCVReturnSuccess && pxbuffer != NULL) {
        
        CVPixelBufferLockBaseAddress(pxbuffer, 0);
        void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
        NSParameterAssert(pxdata != NULL);
        
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGContextRef context = CGBitmapContextCreate(pxdata,
                                                     frameWidth,
                                                     frameHeight,
                                                     8,
                                                     CVPixelBufferGetBytesPerRow(pxbuffer),
                                                     rgbColorSpace,
                                                     (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        NSParameterAssert(context);
        CGContextConcatCTM(context, CGAffineTransformIdentity);
        CGContextDrawImage(context, CGRectMake(0,
                                               0,
                                               frameWidth,
                                               frameHeight),
                           image);
        CGColorSpaceRelease(rgbColorSpace);
        CGContextRelease(context);
        
        CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    }
    
    return pxbuffer;
}
// 视频和音频混合
- (void)mixVideo:(NSString *)videoUrl audio:(NSString *)audioUrl complete:(void (^)(NSData *data, NSError *error))complete
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:videoUrl] && [fileManager fileExistsAtPath:audioUrl])
    {
        // 获取音频URL
        NSURL *audio_inputFileUrl = [NSURL fileURLWithPath:audioUrl];
        
        // 获取视频URL
        NSURL *video_inputFileUrl = [NSURL fileURLWithPath:videoUrl];
        
        // 混合视频和音频
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        
        // 获取混合后的输出路径
        NSString *outputFilePath = [[self myMediaFolder] stringByAppendingPathComponent:@"lf_createMedia_videoAndAudio_mp4.mp4"];
        
        NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
        
        if ([fileManager fileExistsAtPath:outputFilePath])
        {
            [fileManager removeItemAtPath:outputFilePath error:nil];
        }
        
        CMTime nextClipStartTime = kCMTimeZero;
        
        AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:video_inputFileUrl options:nil];
        CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
        AVMutableCompositionTrack *a_compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [a_compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:nextClipStartTime error:nil];
        
        AVURLAsset* audioAsset = [[AVURLAsset alloc]initWithURL:audio_inputFileUrl options:nil];
        CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero, audioAsset.duration);
        AVMutableCompositionTrack *b_compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [b_compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:nextClipStartTime error:nil];
        
        AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
        _assetExport.outputFileType = AVFileTypeMPEG4;
        _assetExport.outputURL = outputFileUrl;
        
        [_assetExport exportAsynchronouslyWithCompletionHandler:^{
            
            NSData *data = [NSData dataWithContentsOfFile:outputFilePath];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complete) complete(data, _assetExport.error);
            });
        }];
    } else {
        NSError *error = [NSError errorWithDomain:@"LFAssetManager_CreateMedia_Error" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Check that the video and audio paths are valid"}];
        if (complete) complete(nil, error);
    }
}

@end
