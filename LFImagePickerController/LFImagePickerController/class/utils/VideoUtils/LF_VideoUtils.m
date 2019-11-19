//
//  VideoUtils.m
//  MEMobile
//
//  Created by LamTsanFeng on 15/11/11.
//  Copyright © 2015年 GZMiracle. All rights reserved.
//

#import "LF_VideoUtils.h"
#import "LF_FileUtility.h"

@implementation LF_VideoUtils

+ (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack
{
    UIImageOrientation orientation = UIImageOrientationUp;
    
    CGAffineTransform t = videoTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        // Portrait
        //        degress = 90;
        orientation = UIImageOrientationRight;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        // PortraitUpsideDown
        //        degress = 270;
        orientation = UIImageOrientationLeft;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        // LandscapeRight
        //        degress = 0;
        orientation = UIImageOrientationUp;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        // LandscapeLeft
        //        degress = 180;
        orientation = UIImageOrientationDown;
    }
    
    return orientation;
}

/** 视频压缩 */
+ (void)encodeVideoWithURL:(NSURL *)videoURL outPath:(NSString *)outPath complete:(void (^)(BOOL isSuccess, NSError *error))complete
{
    [self encodeVideoWithURL:videoURL outPath:outPath presetName:AVAssetExportPreset1280x720 complete:complete];
}

+ (void)encodeVideoWithURL:(NSURL *)videoURL outPath:(NSString *)outPath presetName:(NSString *)presetName complete:(void (^)(BOOL isSuccess, NSError *error))complete
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    [self encodeVideoWithAsset:asset outPath:outPath presetName:presetName complete:complete];
}

+ (void)encodeVideoWithAsset:(AVAsset *)asset outPath:(NSString *)outPath complete:(void (^)(BOOL isSuccess, NSError *error))complete
{
    [self encodeVideoWithAsset:asset outPath:outPath presetName:nil complete:complete];
}

+ (void)encodeVideoWithAsset:(AVAsset *)asset outPath:(NSString *)outPath presetName:(NSString *)presetName complete:(void (^)(BOOL isSuccess, NSError *error))complete
{
    if (complete == nil) return;
    if (asset == nil || outPath.length == 0) {
        complete(NO, nil);
    }
    
    if ([asset isKindOfClass:[AVURLAsset class]]) {
        NSLog(@"压缩前：%@",[LF_FileUtility getFileSizeString:[LF_FileUtility fileSizeForPath:[((AVURLAsset *)asset).URL path]]]);
    }
    CFTimeInterval time = CACurrentMediaTime();
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
    if (videoTrack == nil) {
        complete(NO, nil);
    }
    
    AVMutableVideoComposition *waterMarkVideoComposition;
    
    UIImageOrientation orientation = [self orientationFromAVAssetTrack:videoTrack];
    
    if (orientation != UIImageOrientationUp) {
        waterMarkVideoComposition = [AVMutableVideoComposition videoComposition];
        waterMarkVideoComposition.frameDuration = CMTimeMake(1, 30);
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            //顺时针旋转270°
            //            NSLog(@"视频旋转270度，home按键在右");
            transform = CGAffineTransformTranslate(transform, 0.0, videoTrack.naturalSize.width);
            transform = CGAffineTransformRotate(transform,M_PI_2*3.0);
            waterMarkVideoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
            break;
        case UIImageOrientationRight:
            //顺时针旋转90°
            //            NSLog(@"视频旋转90度,home按键在左");
            transform = CGAffineTransformTranslate(transform, videoTrack.naturalSize.height, 0.0);
            transform = CGAffineTransformRotate(transform,M_PI_2);
            waterMarkVideoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
            break;
        case UIImageOrientationDown:
            //顺时针旋转180°
            //            NSLog(@"视频旋转180度，home按键在上");
            transform = CGAffineTransformTranslate(transform, videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            transform = CGAffineTransformRotate(transform,M_PI);
            waterMarkVideoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
            break;
        default:
            break;
    }
    
    if (waterMarkVideoComposition) {
        AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [asset duration]);
        AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        [roateLayerInstruction setTransform:transform atTime:kCMTimeZero];
        
        roateInstruction.layerInstructions = @[roateLayerInstruction];
        //将视频方向旋转加入到视频处理中
        waterMarkVideoComposition.instructions = @[roateInstruction];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
    }
    
    NSString *exprotPresetName = (presetName.length ? presetName : AVAssetExportPreset1280x720);
    if (![[AVAssetExportSession exportPresetsCompatibleWithAsset:asset] containsObject:exprotPresetName]) {
        exprotPresetName = AVAssetExportPresetHighestQuality;
        NSLog(@"The video is not compatible with presetName. Use AVAssetExportPresetHighestQuality.");
    }

    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:exprotPresetName];
    exportSession.outputURL = [NSURL fileURLWithPath:outPath];
    exportSession.videoComposition = waterMarkVideoComposition;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch ([exportSession status])
         {
             case AVAssetExportSessionStatusCompleted:
                 NSLog(@"MP4 Successful!");
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Export canceled");
                 break;
             default:
                 break;
         }
         NSLog(@"Completed compression in %f s",CACurrentMediaTime() - time);
         NSString *fileSizeStr = [LF_FileUtility getFileSizeString:[LF_FileUtility fileSizeForPath:outPath]];
         NSLog(@"压缩后：%@",fileSizeStr);
         complete([exportSession status] == AVAssetExportSessionStatusCompleted, exportSession.error);
     }];
}


+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode =AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    if (thumbnailImageRef) {
        UIImage *thumbnailImage = [[UIImage alloc]initWithCGImage:thumbnailImageRef];
        CGImageRelease(thumbnailImageRef);
        
        return thumbnailImage;
    }
    
    return nil;
}

+ (void)GIFImageForVideo:(NSURL *)videoURL complete:(void (^)(UIImage *gifImage))complete
{
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *myAsset = [[AVURLAsset alloc] initWithURL:videoURL options:opts];
    CMTimeValue value = myAsset.duration.value;//总帧数
    CMTimeScale timeScale = myAsset.duration.timescale; //timescale为  fps
    long long second = value / timeScale; // 获取视频总时长,单位秒
    
    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:myAsset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;

    NSMutableArray *images = [NSMutableArray array];
    NSMutableArray *times = [NSMutableArray array];
    for (float i = 1; i <= second; i++) {
        NSValue *value = [NSValue valueWithCMTime:CMTimeMakeWithSeconds(i, 60)];
        [times addObject:value];
    }
    __block NSInteger index = times.count;
    
    [assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:
     ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error)
     {
         
         NSLog(@"actual got image at time:%f", CMTimeGetSeconds(actualTime));
         if (image)
         {
             [CATransaction begin];
             [CATransaction setDisableActions:YES];
             
             UIImage *img = [UIImage imageWithCGImage:image];
             
             [images addObject:img];
             
             [CATransaction commit];
         }
         if (--index == 0) {
             if (complete && images.count) {
                 complete([UIImage animatedImageWithImages:images duration:second]);
             }
         }
     }];
}

#pragma mark - 获取视频大小
+ (CGSize)videoNaturalSizeWithPath:(NSString *)path
{
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        NSLog(@"Error reading the transformed video track");
        return CGSizeZero;
    }
    
    // Insert the tracks in the composition's tracks
    AVAssetTrack *track = [assetVideoTracks firstObject];
    
    CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
    return CGSizeMake(fabs(dimensions.width), fabs(dimensions.height));
}

#pragma mark - 获取视频时长
+ (long long)videoSectionTimeWithPath:(NSString *)path
{
    NSURL *videoURL = [NSURL fileURLWithPath:path];
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:opts];
    
    return CMTimeGetSeconds(asset.duration);//asset.duration.value / asset.duration.timescale; // 获取视频总时长,单位秒
}

#pragma mark - 视频能否播放
+ (BOOL)videoCanPlayWithPath:(NSString *)path
{
    NSURL *fileUrl = [NSURL fileURLWithPath:path];
    AVAsset *asset = [AVAsset assetWithURL:fileUrl];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    BOOL canPlayVideo = videoTracks.count;
    return canPlayVideo;
}

@end
