//
//  LFVideoPlayerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFVideoPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import "LFImagePickerController.h"
#import "LFImagePickerHeader.h"
#import "LFAssetManager.h"
#import "UIView+LFFrame.h"
#import "UIAlertView+LF_Block.h"
#import "LF_FileUtility.h"

/** 视频发送大小（10.0M） */
#define kFixVideoSize (10.0 * 1000 * 1000)

@interface LFVideoPlayerController ()
{
    AVPlayer *_player;
    UIButton *_playButton;
    UIImage *_cover;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    UIProgressView *_progress;
    
    UIStatusBarStyle _originStatusBarStyle;
}
@end

@implementation LFVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (imagePickerVc) {
        self.navigationItem.title = imagePickerVc.previewBtnTitleStr;
    }
    [self configMoviePlayer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].statusBarStyle = _originStatusBarStyle;
}

- (void)configMoviePlayer {
    [[LFAssetManager manager] getPhotoWithAsset:_model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        _cover = photo;
    }];
    [[LFAssetManager manager] getVideoWithAsset:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        _player = [AVPlayer playerWithPlayerItem:playerItem];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame = self.view.bounds;
        [self.view.layer addSublayer:playerLayer];
        [self addProgressObserver];
        [self configPlayButton];
        [self configBottomToolBar];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    }];
}

/// Show progress，do it next time / 给播放器添加进度更新,下次加上
- (void)addProgressObserver{
    AVPlayerItem *playerItem = _player.currentItem;
    UIProgressView *progress = _progress;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        if (current) {
            [progress setProgress:(current/total) animated:YES];
        }
    }];
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(0, 64, self.view.width, self.view.height - 64 - 44);
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay.png") forState:UIControlStateNormal];
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlayHL.png") forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playButton];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(self.view.width - 44 - 12, 0, 44, 44);
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (imagePickerVc) {
        [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
        [_doneButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:@"完成" forState:UIControlStateNormal];
        [_doneButton setTitleColor:[UIColor colorWithRed:(83/255.0) green:(179/255.0) blue:(17/255.0) alpha:1.0] forState:UIControlStateNormal];
    }
    [_toolBar addSubview:_doneButton];
    [self.view addSubview:_toolBar];
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        [self.navigationController setNavigationBarHidden:YES];
        _toolBar.hidden = YES;
        [_playButton setImage:nil forState:UIControlStateNormal];
        if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = YES;
    } else {
        [self pausePlayerAndShowNaviBar];
    }
}

- (void)doneButtonClick {
    [self compressSelectVideoCompleteToSave];
}

#pragma mark - 选择视频后压缩保存
- (void)compressSelectVideoCompleteToSave{
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    NSURL *url = [[LFAssetManager manager] getURLInPlayer:_player];
    NSString *name = [url lastPathComponent];
    if (![name hasPrefix:@".mp4"]) {
        name = [name stringByDeletingPathExtension];
        name = [name stringByAppendingPathExtension:@"mp4"];
    }
    __block NSString *videoPath = nil;
    if (name) {
        videoPath = [[LFAssetManager CacheVideoPath] stringByAppendingPathComponent:name];
    }
    
    __weak typeof(self) weakSelf = self;
    void(^compressAndCacheVideoBlock)(double fileSize, NSString *videoPath) = ^(double fileSize, NSString *videoPath) {
        if (fileSize > kFixVideoSize ) {
            /** 视频大于5M的，不发送 */
            NSString *msg = [NSString stringWithFormat:@"你选择的视频文件尺寸过大，无法发送。请选择文件尺寸较小或者时间较短的视频"];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:msg cancelButtonTitle:nil otherButtonTitles:@"确认" block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            }];
            [alertView show];
        }else{
            [weakSelf showSheetActionWithContent:[LF_FileUtility getFileSizeString:fileSize] videoPath:videoPath];
        }
    };
    /** 判断视频是否存在 */
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        /** 大小:%lldK */
        double fileSize = [LF_FileUtility fileSizeForPath:videoPath];
        if (compressAndCacheVideoBlock) compressAndCacheVideoBlock(fileSize, videoPath);
    } else {
        [imagePickerVc showProgressHUDText:@"正在压缩..."];
        /** 不存在就压缩 */
        [[LFAssetManager manager] compressAndCacheVideoWithAsset:self.model.asset completion:^(NSString *path) {
            if (path.length == 0) {
                [imagePickerVc showProgressHUDText:@"压缩失败"];
            }else{
                [imagePickerVc hideProgressHUD];
                double fileSize = [LF_FileUtility fileSizeForPath:path];
                if (compressAndCacheVideoBlock) compressAndCacheVideoBlock(fileSize, path);
            }
        }];
    }
}

#pragma mark - 压缩完后提示
- (void)showSheetActionWithContent:(NSString *)content videoPath:(NSString *)videoPath{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSString *name = [NSString stringWithFormat:@"视频压缩后文件大小为%@，确定要发送吗？",content];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:name cancelButtonTitle:@"取消" otherButtonTitles:@"发送" block:^(UIAlertView *alertView, NSInteger buttonIndex) {
        switch (buttonIndex) {
            case 0:
                
                break;
            case 1:
            {
                if (self.navigationController) {
                    if (imagePickerVc.autoDismiss) {
                        [self.navigationController dismissViewControllerAnimated:YES completion:^{
                            [self callDelegateMethod:_cover path:videoPath];
                        }];
                    } else {
                        [self callDelegateMethod:_cover path:videoPath];
                    }
                } else {
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self callDelegateMethod:_cover path:videoPath];
                    }];
                }
                
            }
                break;
            default:
                break;
        }
    }];
    [alertView show];
}

- (void)callDelegateMethod:(UIImage *)cover path:(NSString *)videoPath
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    id <LFImagePickerControllerDelegate> pickerDelegate = (id <LFImagePickerControllerDelegate>)imagePickerVc.pickerDelegate;

    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingVideo:cover sourceAssets:_model.asset];
    } else if (imagePickerVc.didFinishPickingVideoHandle) {
        imagePickerVc.didFinishPickingVideoHandle(cover,_model.asset);
    }
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingVideo:path:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingVideo:cover path:videoPath];
    } else if (imagePickerVc.didFinishPickingVideoWithThumbnailAndPathHandle) {
        imagePickerVc.didFinishPickingVideoWithThumbnailAndPathHandle(cover, videoPath);
    }
}


#pragma mark - Notification Method

- (void)pausePlayerAndShowNaviBar {
    [_player pause];
    _toolBar.hidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    [_playButton setImage:bundleImageNamed(@"MMVideoPreviewPlay.png") forState:UIControlStateNormal];
    if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
