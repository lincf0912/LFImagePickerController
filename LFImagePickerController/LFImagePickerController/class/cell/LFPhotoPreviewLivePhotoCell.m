//
//  LFPhotoPreviewLivePhotoCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/1.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewLivePhotoCell.h"
#import "LFAssetManager.h"
#import <PhotosUI/PhotosUI.h>

@interface LFPhotoPreviewLivePhotoCell () <PHLivePhotoViewDelegate>

@property (nonatomic, strong) PHLivePhotoView *livePhotoView;

@end

@implementation LFPhotoPreviewLivePhotoCell

#pragma mark - 重写父类方法
/** 创建显示视图 */
- (UIView *)subViewInitDisplayView
{
    if (_livePhotoView == nil) {
        _livePhotoView = [[PHLivePhotoView alloc] init];
        _livePhotoView.muted = YES;
        _livePhotoView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _livePhotoView;
}
/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    _livePhotoView.delegate =  nil;
    [_livePhotoView stopPlayback];
    _livePhotoView.livePhoto = nil;
}
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    if (model.subType == LFAssetSubMediaTypeLivePhoto) { /** live photo */
        [[LFAssetManager manager] getLivePhotoWithAsset:model.asset photoWidth:[UIScreen mainScreen].bounds.size.width completion:^(PHLivePhoto *livePhoto, NSDictionary *info, BOOL isDegraded) {
            
            if ([model isEqual:self.model]) { /** live photo */
                self.livePhotoView.livePhoto = livePhoto;
                if (model.closeLivePhoto == NO) {
                    self.livePhotoView.delegate = self;
                    [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
                }
                if (completeHandler) {
                    completeHandler(livePhoto, info, isDegraded);
                }
            }
            
        } progressHandler:progressHandler networkAccessAllowed:YES];
    } else {
        [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
    }
}

- (void)willDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeLivePhoto && self.model.closeLivePhoto == NO) { /** live photo */
        _livePhotoView.delegate = self;
        [_livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
    }
}

- (void)didEndDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeLivePhoto) { /** live photo */
        _livePhotoView.delegate = nil;
        [_livePhotoView stopPlayback];
    }
}

#pragma mark - PHLivePhotoViewDelegate
- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle
{
    if (playbackStyle == PHLivePhotoViewPlaybackStyleFull) {
        [livePhotoView startPlaybackWithStyle:playbackStyle];
    }
}
@end
