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
#import "LFVideoEditManager.h"
#import "LFVideoEdit.h"

@interface LFPhotoPreviewVideoCell ()

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, weak) AVPlayerLayer *playerLayer;

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

- (void)layoutSubviews
{
    [super layoutSubviews];
    _playerLayer.frame = self.contentView.bounds;
}

/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    self.imageView.hidden = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playButton removeFromSuperview];
    _playButton = nil;
    [_playerLayer removeFromSuperlayer];
    _playerLayer.player = nil;
    _playerLayer = nil;
    _player = nil;
}
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    /** 优先显示编辑图片 */
    LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:model];
    if (videoEdit.editPreviewImage) {
        self.previewImage = videoEdit.editPreviewImage;
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoEdit.editFinalURL];
        [self readyToPlay:playerItem];
    } else {
        [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
        if (model.type == LFAssetMediaTypeVideo) { /** video */
            [[LFAssetManager manager] getVideoWithAsset:model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
                [self readyToPlay:playerItem];
            }];
        }
    }
}

- (void)readyToPlay:(AVPlayerItem *)playerItem
{
    _player = [AVPlayer playerWithPlayerItem:playerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    playerLayer.frame = self.contentView.bounds;
    [self.contentView.layer addSublayer:playerLayer];
    [_playerLayer removeFromSuperlayer];
    _playerLayer = playerLayer;
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

- (void)didPauseCell
{
    if (self.model.type == LFAssetMediaTypeVideo) { /** 视频处理 */
        [_player pause];
        [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay.png") forState:UIControlStateNormal];
    }
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = self.contentView.bounds;
    _playButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay.png") forState:UIControlStateNormal];
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlayHL.png") forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_playButton];
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        [_playButton setImage:nil forState:UIControlStateNormal];
        _isPlaying = YES;
        if ([self.delegate respondsToSelector:@selector(lf_photoPreviewCellSingleTapHandler:)]) {
            [self.delegate lf_photoPreviewCellSingleTapHandler:self];
        }
    } else {
        [self pausePlayerAndShowNaviBar];
    }
}

- (void)pausePlayerAndShowNaviBar {
    [_player pause];
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay.png") forState:UIControlStateNormal];
    _isPlaying = NO;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (AVAsset *)asset
{
    return self.player.currentItem.asset;
}


@end
