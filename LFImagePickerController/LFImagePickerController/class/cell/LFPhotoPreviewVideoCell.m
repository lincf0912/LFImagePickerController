//
//  LFPhotoPreviewVideoCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewVideoCell.h"
#import "LFImagePickerHeader.h"
#import "LFPhotoPreviewCell_property.h"
#import "LFAssetManager.h"

#ifdef LF_MEDIAEDIT
#import "LFVideoEditManager.h"
#import "LFVideoEdit.h"
#endif

@interface LFPhotoPreviewVideoPlayerView : UIView

@end

@implementation LFPhotoPreviewVideoPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return self;
}

@end

@interface LFPhotoPreviewVideoCell ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) LFPhotoPreviewVideoPlayerView *playerView;

@property (nonatomic, assign) BOOL waitForReadyToPlay;

@property (nonatomic, assign) CGSize dimensions;
@end

@implementation LFPhotoPreviewVideoCell

@dynamic delegate;

#pragma mark - 重写父类方法
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
//        self.scrollView.maximumZoomScale = 1.f;
//        self.scrollView.minimumZoomScale = 1.f;
//        [self removeGestureRecognizer:self.tap1];
//        [self removeGestureRecognizer:self.tap2];
    }
    return self;
}

/** 创建显示视图 */
- (UIView *)subViewInitDisplayView
{
    if (_playerView == nil) {
        _playerView = [[LFPhotoPreviewVideoPlayerView alloc] init];
    }
    return _playerView;
}

- (CGSize)subViewImageSize
{
    if (self.dimensions.width) {
        return self.dimensions;
    }
    return self.imageView.image.size;
}

/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    _waitForReadyToPlay = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    ((AVPlayerLayer *)_playerView.layer).player = nil;
    _player = nil;
}
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    if (model.type == LFAssetMediaTypeVideo) { /** video */
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:model];
        if (videoEdit.editPreviewImage) {
            self.previewImage = videoEdit.editPreviewImage;
            AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoEdit.editFinalURL];
            [self readyToPlay:playerItem];
        }
        else {
#endif
            if (model.previewVideoUrl) { /** 显示自定义图片 */
                self.previewImage = model.thumbnailImage;
                AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:model.previewVideoUrl];
                [self readyToPlay:playerItem];
            } else {
                // 先获取缩略图
                PHImageRequestID imageRequestID = [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:self.bounds.size.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                    if (completeHandler) {
                        completeHandler(photo, info, YES);
                    }
                }];
                [[LFAssetManager manager] getVideoWithAsset:model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    if ([model isEqual:self.model]) {
                        [[LFAssetManager manager] cancelImageRequest:imageRequestID];
                        [self readyToPlay:playerItem];
                        AVAssetTrack *track = [[playerItem.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                        CGSize dimensions = CGSizeApplyAffineTransform(track.naturalSize, track.preferredTransform);
                        float videoWidth = fabs(dimensions.width);
                        float videoHeight = fabs(dimensions.height);
                        self.dimensions = CGSizeMake(videoWidth, videoHeight);
                        self.isFinalData = YES;
                        [self resizeSubviews]; // 刷新subview的位置。
                    }
                }];
            }
#ifdef LF_MEDIAEDIT
        }
#endif
    } else {
        [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
    }
}

- (void)readyToPlay:(AVPlayerItem *)playerItem
{
    if (_player) {
        [_player pause];
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:NULL];
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    ((AVPlayerLayer *)_playerView.layer).player = _player;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerNotify) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

//- (void)changeVideoPlayer:(AVAsset *)asset image:(UIImage *)image
//{
//    if (asset) {
//        [self subViewReset];
//        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
//        self.previewImage = image;
//        [self readyToPlay:playerItem];
//    }
//}



- (void)didDisplayCell
{
    [super didDisplayCell];
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [self didPlayCell];
    }
}

- (void)willEndDisplayCell
{
    [super willEndDisplayCell];
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        _waitForReadyToPlay = NO;
        [self didPauseCell];
    }
}

- (void)didEndDisplayCell
{
    [super didEndDisplayCell];
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [_player.currentItem seekToTime:CMTimeMake(0, 1) completionHandler:nil];
    }
}

- (void)didPlayCell
{
    if (self.model.type == LFAssetMediaTypeVideo && _player.rate == 0.0f) { /** 视频处理 */
        if (_player.currentItem.status == AVPlayerStatusReadyToPlay) {
            CMTime currentTime = _player.currentItem.currentTime;
            CMTime durationTime = _player.currentItem.duration;
            if (currentTime.value == durationTime.value) {
                __weak typeof(self) weakSelf = self;
                [_player.currentItem seekToTime:CMTimeMake(0, 1) completionHandler:^(BOOL finished) {
                    [weakSelf.player play];
                    if ([weakSelf.delegate respondsToSelector:@selector(lf_photoPreviewVideoCellDidPlayHandler:)]) {
                        [weakSelf.delegate lf_photoPreviewVideoCellDidPlayHandler:weakSelf];
                    }
                }];
            } else {
                [_player play];
                if ([self.delegate respondsToSelector:@selector(lf_photoPreviewVideoCellDidPlayHandler:)]) {
                    [self.delegate lf_photoPreviewVideoCellDidPlayHandler:self];
                }
            }
        } else {
            _waitForReadyToPlay = YES;
        }
    }
}

- (void)didPauseCell
{
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [_player pause];
        if ([self.delegate respondsToSelector:@selector(lf_photoPreviewVideoCellDidStopHandler:)]) {
            [self.delegate lf_photoPreviewVideoCellDidStopHandler:self];
        }
    }
}

- (BOOL)isPlaying
{
    return _player.rate != 0.0f;
}

#pragma mark - Notification Method
- (void)pausePlayerNotify
{
//    [_player.currentItem seekToTime:CMTimeMake(0, 1) completionHandler:nil];
    if ([self.delegate respondsToSelector:@selector(lf_photoPreviewVideoCellDidStopHandler:)]) {
        [self.delegate lf_photoPreviewVideoCellDidStopHandler:self];
    }
}


- (void)dealloc {
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AVAsset *)asset
{
    return self.player.currentItem.asset;
}

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    switch (status)
    {
        case AVPlayerItemStatusReadyToPlay:
        {
            if (_waitForReadyToPlay) {
                _waitForReadyToPlay = NO;
                [self didPlayCell];
            }
        }
            break;
        default:
            break;
    }
}


@end
