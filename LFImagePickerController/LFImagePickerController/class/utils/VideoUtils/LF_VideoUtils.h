//
//  VideoUtils.h
//  MEMobile
//
//  Created by LamTsanFeng on 15/11/11.
//  Copyright © 2015年 GZMiracle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface LF_VideoUtils : NSObject

/** 将视频轨迹AVAssetTrack转换为UIImageOrientation */
+ (UIImageOrientation)orientationFromAVAssetTrack:(AVAssetTrack *)videoTrack;

/** 视频压缩URL */
+ (void)encodeVideoWithURL:(NSURL *)videoURL outPath:(NSString *)outPath complete:(void (^)(BOOL isSuccess, NSError *error))complete;
+ (void)encodeVideoWithURL:(NSURL *)videoURL outPath:(NSString *)outPath presetName:(NSString *)presetName complete:(void (^)(BOOL isSuccess, NSError *error))complete;

/** 视频压缩Asset */
+ (void)encodeVideoWithAsset:(AVAsset *)asset outPath:(NSString *)outPath complete:(void (^)(BOOL isSuccess, NSError *error))complete;
+ (void)encodeVideoWithAsset:(AVAsset *)asset outPath:(NSString *)outPath presetName:(NSString *)presetName complete:(void (^)(BOOL isSuccess, NSError *error))complete;

/*
 * 获取第N帧的图片
 *videoURL:视频地址(本地/网络)
 *time      :第N帧
 */
+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

/**
 *  @author lincf, 16-06-08 10:06:01
 *
 *  获取视频大小
 *
 *  @param path 视频路径
 *
 *  @return 视频大小CGSize
 */
+ (CGSize)videoNaturalSizeWithPath:(NSString *)path;


/**
 *  @author lincf, 16-06-13 15:06:59
 *
 *  获取视频时长
 *
 *  @param path 视频路径
 *
 *  @return 视频时长long long
 */
+ (long long)videoSectionTimeWithPath:(NSString *)path;

/**
 *  @author lincf
 *
 *  视频能否播放
 *
 *  @param path 视频路径
 *
 */
+ (BOOL)videoCanPlayWithPath:(NSString *)path;

@end
