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
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) LFPhotoPreviewVideoPlayerView *playerView;

@property (nonatomic, assign) BOOL waitForReadyToPlay;

@end

@implementation LFPhotoPreviewVideoCell

#pragma mark - 重写父类方法
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.scrollView.maximumZoomScale = 1.f;
        self.scrollView.minimumZoomScale = 1.f;
        [self removeGestureRecognizer:self.tap1];
        [self removeGestureRecognizer:self.tap2];
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

/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    _waitForReadyToPlay = NO;
    self.imageView.hidden = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playButton removeFromSuperview];
    _playButton = nil;
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
                [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
                [[LFAssetManager manager] getVideoWithAsset:model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
                    if ([model isEqual:self.model]) {
                        [self readyToPlay:playerItem];
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
    [self configPlayButton];
    self.imageView.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerNotify) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
}

- (void)changeVideoPlayer:(AVAsset *)asset image:(UIImage *)image
{
    if (asset) {
        [self subViewReset];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:asset];
        self.previewImage = image;
        [self readyToPlay:playerItem];
    }
}



- (void)willDisplayCell
{
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        
    }
}

- (void)didEndDisplayCell
{
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [self didPauseCell];
        [_player.currentItem seekToTime:CMTimeMake(0, 1)];
    }
}

- (void)didPlayCell
{
    if (self.model.type == LFAssetMediaTypeVideo && _player.rate == 0.0f) { /** 视频处理 */
        if (_player.currentItem.status == AVPlayerStatusReadyToPlay) {
            CMTime currentTime = _player.currentItem.currentTime;
            CMTime durationTime = _player.currentItem.duration;
            if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
            [_player play];
            [_playButton setImage:nil forState:UIControlStateNormal];
            [_playButton setImage:nil forState:UIControlStateHighlighted];
            _isPlaying = YES;
        } else {
            _waitForReadyToPlay = YES;
        }
    }
}

- (void)didPauseCell
{
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [_player pause];
        [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay") forState:UIControlStateNormal];
        [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlayHL") forState:UIControlStateHighlighted];
        _isPlaying = NO;
    }
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = self.contentView.bounds;
    _playButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay") forState:UIControlStateNormal];
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlayHL") forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _playButton.hidden = YES;
    [self.contentView addSubview:_playButton];
}

#pragma mark - Click Event

- (void)playButtonClick {
    if (_player.rate == 0.0f) {
        [self didPlayCell];
        if ([self.delegate respondsToSelector:@selector(lf_photoPreviewCellSingleTapHandler:)]) {
            [self.delegate lf_photoPreviewCellSingleTapHandler:self];
        }
    } else {
        [self pausePlayerAndShowNaviBar];
    }
}

- (void)pausePlayerAndShowNaviBar {
    [self didPauseCell];
    if ([self.delegate respondsToSelector:@selector(lf_photoPreviewCellSingleTapHandler:)]) {
        [self.delegate lf_photoPreviewCellSingleTapHandler:self];
    }
}

#pragma mark - Notification Method
- (void)pausePlayerNotify
{
    [self pausePlayerAndShowNaviBar];
    [_player.currentItem seekToTime:CMTimeMake(0, 1)];
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
            _playButton.hidden = NO;
            if (_waitForReadyToPlay) {
                [self didPlayCell];
            }
        }
            break;
        default:
            break;
    }
}


@end
