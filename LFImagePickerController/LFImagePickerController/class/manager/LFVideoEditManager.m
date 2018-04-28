//
//  LFVideoEditManager.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifdef LF_MEDIAEDIT
#import "LFVideoEditManager.h"
#import "LFImagePickerHeader.h"
#import "LFVideoEdit.h"
#import "LFAsset.h"
#import "LFResultObject_property.h"
#import "LFAssetManager.h"
#import "LF_VideoUtils.h"

@interface LFVideoEditManager ()

@property (nonatomic, strong) NSMutableDictionary *videoEditDict;
@end

@implementation LFVideoEditManager

static LFVideoEditManager *manager;
+ (instancetype)manager {
    if (manager == nil) {
        manager = [[self alloc] init];
        manager.videoEditDict = [@{} mutableCopy];
    }
    return manager;
}

+ (void)free
{
    [manager.videoEditDict removeAllObjects];
    manager = nil;
}

/** 设置编辑对象 */
- (void)setVideoEdit:(LFVideoEdit *)obj forAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    if (asset.asset) {
        if (asset.name.length) {
            if (obj) {
                [weakSelf.videoEditDict setObject:obj forKey:asset.name];
            } else {
                [weakSelf.videoEditDict removeObjectForKey:asset.name];
            }
        } else {
            [[LFAssetManager manager] requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    if (obj) {
                        [weakSelf.videoEditDict setObject:obj forKey:name];
                    } else {
                        [weakSelf.videoEditDict removeObjectForKey:name];
                    }
                }
            }];
        }
    }
}
/** 获取编辑对象 */
- (LFVideoEdit *)videoEditForAsset:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    __block LFVideoEdit *videoEdit = nil;
    if (asset.asset) {
        if (asset.name.length) {
            videoEdit = [weakSelf.videoEditDict objectForKey:asset.name];
        } else {
            [[LFAssetManager manager] requestForAsset:asset.asset complete:^(NSString *name) {
                if (name.length) {
                    videoEdit = [weakSelf.videoEditDict objectForKey:name];
                }
            }];
        }
    }
    return videoEdit;
}


/**
 通过asset解析视频

 @param asset LFAsset
 @param presetName 压缩预设名称 nil则默认为AVAssetExportPresetMediumQuality
 @param completion 回调
 */
- (void)getVideoWithAsset:(LFAsset *)asset
               presetName:(NSString *)presetName
               completion:(void (^)(LFResultVideo *resultVideo))completion
{
    if (presetName.length == 0) {
        presetName = AVAssetExportPresetMediumQuality;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        LFVideoEdit *videoEdit = [self videoEditForAsset:asset];
        /** 图片文件名 */
        NSString *videoName = asset.name;
        videoName = [videoName stringByDeletingPathExtension];
        videoName = [[videoName stringByAppendingString:@"_Edit"] stringByAppendingPathExtension:@"mp4"];
        
        void(^VideoResultComplete)(NSString *, NSString *) = ^(NSString *path, NSString *name) {
            
            LFResultVideo *result = [LFResultVideo new];
            result.asset = asset.asset;
            result.coverImage = videoEdit.editPreviewImage;
            if (path.length) {
                NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                                 forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
                AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:opts];
                NSData *data = [NSData dataWithContentsOfFile:path];
                NSTimeInterval duration = CMTimeGetSeconds(urlAsset.duration);
                
                NSArray *assetVideoTracks = [urlAsset tracksWithMediaType:AVMediaTypeVideo];
                CGSize size = CGSizeZero;
                if (assetVideoTracks.count > 0)
                {
                    // Insert the tracks in the composition's tracks
                    AVAssetTrack *track = [assetVideoTracks firstObject];
                    
                    CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
                    size = CGSizeMake(fabs(dimensions.width), fabs(dimensions.height));
                }
                
                
                result.data = data;
                result.url = [NSURL fileURLWithPath:path];
                result.duration = duration;
                
                LFResultInfo *info = [LFResultInfo new];
                result.info = info;
                
                /** 文件名 */
                info.name = name;
                /** 大小 */
                info.byte = data.length;
                /** 宽高 */
                info.size = size;
            }
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) completion(result);
            });
        };
        
        
        NSString *videoPath = [[LFAssetManager CacheVideoPath] stringByAppendingPathComponent:videoName];
        AVAsset *av_asset = [AVURLAsset assetWithURL:videoEdit.editFinalURL];
        [LF_VideoUtils encodeVideoWithAsset:av_asset outPath:videoPath presetName:presetName complete:^(BOOL isSuccess, NSError *error) {
            if (VideoResultComplete) VideoResultComplete(videoPath, videoName);
        }];
    });
}
@end
#endif
