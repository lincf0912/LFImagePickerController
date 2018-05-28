//
//  ViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "ViewController.h"
#import "LFImagePickerController.h"

#import "UIImage+LF_Format.h"
#import "LFAssetManager.h"
#import "LFAssetManager+CreateMedia.h"

@interface ViewController () <LFImagePickerControllerDelegate, UIDocumentInteractionControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageVIew;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) AVPlayerLayer *playerLayer;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (assign, nonatomic) BOOL isCreateGif;
@property (assign, nonatomic) BOOL isCreateMP4;

/** share */
@property (strong, nonatomic) UIDocumentInteractionController *documentInConVC;
@property (strong, nonatomic) NSString *sharePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _playerLayer.bounds = self.imageView.bounds;
}


- (IBAction)buttonActionNormal:(id)sender {
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowTakePicture = NO;
//    imagePicker.maxVideosCount = 1; /** 解除混合选择- 要么1个视频，要么9个图片 */
//    imagePicker.sortAscendingByCreateDate = NO;
//    imagePicker.allowEditing = NO;
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
//    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
//    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingGif = YES; /** 支持GIF */
    imagePicker.allowPickingLivePhoto = YES; /** 支持Live Photo */
//    imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
//    imagePicker.defaultAlbumName = @"123"; /** 指定默认显示相册 */
//    imagePicker.displayImageFilename = YES; /** 显示文件名称 */
//    imagePicker.thumbnailCompressSize = 0.f; /** 不需要缩略图 */
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}
- (IBAction)buttonActionFriendCircle:(id)sender {
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowTakePicture = NO;
    imagePicker.maxVideosCount = 1; /** 解除混合选择- 要么1个视频，要么9个图片 */
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
    imagePicker.allowPickingGif = YES; /** 支持GIF */
    imagePicker.allowPickingLivePhoto = YES; /** 支持Live Photo */
    imagePicker.maxVideoDuration = 10; /** 10秒视频 */
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonActionPreviewAsset:(id)sender {
    int limit = 10;
    [[LFAssetManager manager] getCameraRollAlbum:YES allowPickingImage:YES fetchLimit:limit ascending:YES completion:^(LFAlbum *model) {
        [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:YES allowPickingImage:YES fetchLimit:limit ascending:NO completion:^(NSArray<LFAsset *> *models) {
            NSMutableArray *array = [@[] mutableCopy];
            for (LFAsset *asset in models) {
                [array addObject:asset.asset];
            }
            LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedAssets:array index:0];
            imagePicker.pickerDelegate = self;
            imagePicker.supportAutorotate = YES;
//            imagePicker.allowPickingGif = YES; /** 支持GIF */
//            imagePicker.maxVideosCount = 1; /** 解除混合选择- 要么1个视频，要么9个图片 */
            /** 全选 */
//            imagePicker.selectedAssets = array;
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    }];
}

- (IBAction)buttonActionPreviewImage:(id)sender {
    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"3" ofType:@"gif"];
//    [UIImage imageNamed:@"3.gif"] //这样加载是静态图片
    NSArray *array = @[[UIImage imageNamed:@"1.jpeg"], [UIImage imageNamed:@"2.jpeg"], [UIImage LF_imageWithImagePath:gifPath]];
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedPhotos:array index:0 complete:^(NSArray *photos) {
        [self.thumbnailImageVIew setImage:nil];
        [self.imageView setImage:photos.firstObject];
    }];
    /** 全选 */
    imagePicker.selectedAssets = array;
    /** 关闭自动选中 */
    imagePicker.autoSelectCurrentImage = NO;
    imagePicker.supportAutorotate = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (IBAction)buttonAction4_c_gif:(id)sender {
    self.isCreateGif = YES;
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowPickingVideo = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (IBAction)buttonAction5_c_mp4:(id)sender {
    self.isCreateMP4 = YES;
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowPickingVideo = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingResult:(NSArray <LFResultObject /* <LFResultImage/LFResultVideo> */*> *)results;
{
    self.sharePath = nil;
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
    NSString *thumbnailFilePath = [documentPath stringByAppendingPathComponent:@"thumbnail"];
    NSString *originalFilePath = [documentPath stringByAppendingPathComponent:@"original"];
    
    NSFileManager *fileManager = [NSFileManager new];
    if (![fileManager fileExistsAtPath:thumbnailFilePath])
    {
        [fileManager createDirectoryAtPath:thumbnailFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fileManager fileExistsAtPath:originalFilePath])
    {
        [fileManager createDirectoryAtPath:originalFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [_playerLayer removeFromSuperlayer];
    
    UIImage *thumbnailImage = nil;
    UIImage *originalImage = nil;
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] init];
    playerLayer.bounds = self.imageView.bounds;
    playerLayer.anchorPoint = CGPointZero;
    [self.imageView.layer addSublayer:playerLayer];
    _playerLayer = playerLayer;
    
    NSMutableArray <UIImage *>*images = [@[] mutableCopy];
    
    for (NSInteger i = 0; i < results.count; i++) {
        LFResultObject *result = results[i];
        if ([result isKindOfClass:[LFResultImage class]]) {
            
            LFResultImage *resultImage = (LFResultImage *)result;
            
            if (playerLayer.player == nil) {
                thumbnailImage = resultImage.thumbnailImage;
                originalImage = resultImage.originalImage;
                NSString *name = resultImage.info.name;
                NSData *thumnailData = resultImage.thumbnailData;
                NSData *originalData = resultImage.originalData;
                CGFloat byte = resultImage.info.byte;
                CGSize size = resultImage.info.size;
                
                
                /** 缩略图保存到路径 */
                //            [thumnailData writeToFile:[thumbnailFilePath stringByAppendingPathComponent:name] atomically:YES];
                /** 原图保存到路径 */
                if ([originalData writeToFile:[originalFilePath stringByAppendingPathComponent:name] atomically:YES]) {
                    self.sharePath = [originalFilePath stringByAppendingPathComponent:name];
                }
                
                NSLog(@"🎉🚀Info name:%@ -- infoLength:%fK -- thumnailLength:%fK -- originalLength:%fK -- infoSize:%@", name, byte/1000.0, thumnailData.length/1000.0, originalData.length/1000.0, NSStringFromCGSize(size));
                
                [images addObject:originalImage];
            }
            
        } else if ([result isKindOfClass:[LFResultVideo class]]) {
            
            LFResultVideo *resultVideo = (LFResultVideo *)result;
            if (playerLayer.player == nil && originalImage == nil) {
                /** 保存视频 */
                if ([resultVideo.data writeToFile:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name] atomically:YES]) {
                    self.sharePath = [originalFilePath stringByAppendingPathComponent:resultVideo.info.name];
                }
                
                thumbnailImage = resultVideo.coverImage;
                
                AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name]]];
                [playerLayer setPlayer:player];
                [player play];
            }
            NSLog(@"🎉🚀Info name:%@ -- infoLength:%fK -- videoLength:%fK -- infoSize:%@", resultVideo.info.name, resultVideo.info.byte/1000.0, resultVideo.data.length/1000.0, NSStringFromCGSize(resultVideo.info.size));
        } else {
            /** 无法处理的数据 */
            NSLog(@"%@", result.error);
        }
    }
    
    if (self.isCreateGif) {
#warning Create gif
        NSData *imageData = [[LFAssetManager manager] createGifDataWithImages:images size:[UIScreen mainScreen].bounds.size duration:images.count loopCount:0 error:nil];
        NSString *path = [originalFilePath stringByAppendingPathComponent:@"newGif.gif"];
        if ([imageData writeToFile:path atomically:YES]) {
            self.sharePath = path;
        }
        UIImage *gif = [UIImage LF_imageWithImageData:imageData];
        if (gif) {
            originalImage = gif;
        }
    } else if (self.isCreateMP4) {
#warning Create mp4
        thumbnailImage = images.firstObject;
        originalImage = nil;
        [[LFAssetManager manager] createMP4WithImages:images size:[UIScreen mainScreen].bounds.size complete:^(NSData *data, NSError *error) {
            if (error) {
                NSLog(@"create MP4 error:%@", error);
            } else {
                NSString *path = [originalFilePath stringByAppendingPathComponent:@"newMP4.mp4"];
                if ([data writeToFile:path atomically:YES]) {
                    self.sharePath = path;
                }
                AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:path]];
                [playerLayer setPlayer:player];
                [player play];
            }
        }];
    }
    
    [self.thumbnailImageVIew setImage:thumbnailImage];
    [self.imageView setImage:originalImage];
    
    self.isCreateGif = NO;
    self.isCreateMP4 = NO;
}

- (void)lf_imagePickerControllerDidCancel:(LFImagePickerController *)picker
{
    self.isCreateGif = NO;
    self.isCreateMP4 = NO;
}


#pragma mark - Share
- (IBAction)buttonAction6_share:(id)sender {
    if (self.sharePath.length == 0) {
        NSLog(@"分享失败！");
        return;
    }
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        _documentInConVC = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.sharePath]];
        _documentInConVC.delegate = self;
        [_documentInConVC presentOptionsMenuFromRect:self.shareButton.frame inView:self.view animated:YES];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller{
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller{
    return self.view.frame;
}

@end
