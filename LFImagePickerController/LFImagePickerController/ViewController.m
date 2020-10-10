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

#import <MobileCoreServices/UTCoreTypes.h>

@interface LFCustomObject : NSObject <LFAssetImageProtocol>

/// LFAssetImageProtocol

@property (nonatomic, strong) UIImage *assetImage;

+ (instancetype)lf_CustomObjectWithImage:(UIImage *)image;

@end

@implementation LFCustomObject

+ (instancetype)lf_CustomObjectWithImage:(UIImage *)image
{
    LFCustomObject *object = [[[self class] alloc] init];
    object.assetImage = image;
    return object;
}

@end

@interface LFPhotoObject : NSObject <LFAssetPhotoProtocol>

/// LFAssetPhotoProtocol

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) UIImage *originalImage;

@property (nonatomic, strong) UIImage *thumbnailImage;

+ (instancetype)lf_PhotoObjectWithImage:(UIImage *)image thumbnailImage:(UIImage *)thumbnailImage;

@end

@implementation LFPhotoObject

+ (instancetype)lf_PhotoObjectWithImage:(UIImage *)image thumbnailImage:(UIImage *)thumbnailImage
{
    LFPhotoObject *object = [[[self class] alloc] init];
    object.originalImage = image;
    object.thumbnailImage = thumbnailImage;
    return object;
}

@end

@interface ViewController () <LFImagePickerControllerDelegate, UIDocumentInteractionControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
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

@property (copy, nonatomic) lf_takePhotoHandler handler;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /** 选择有透明通道的png，需要调整背景颜色才能看到图片，实际上图片是正常的。 */
    // self.view.backgroundColor = [UIColor yellowColor];
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
//    [LFAssetManager cleanCacheVideoPath];
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePicker.allowTakePicture = NO;
//    imagePicker.maxVideosCount = 1; /** 解除混合选择- 要么1个视频，要么9个图片 */
//    imagePicker.sortAscendingByCreateDate = NO;
//    imagePicker.allowEditing = NO;
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
//    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
//    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingType = LFPickingMediaTypeALL;
//    imagePicker.autoPlayLivePhoto = NO; /** 自动播放live photo */
//    imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
//    imagePicker.defaultAlbumName = @"动图"; /** 指定默认显示相册 */
//    imagePicker.displayImageFilename = YES; /** 显示文件名称 */
//    imagePicker.thumbnailCompressSize = 0.f; /** 不需要缩略图 */
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}
- (IBAction)buttonActionFriendCircle:(id)sender {
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePicker.allowTakePicture = NO;
    imagePicker.maxVideosCount = 1; /** 解除混合选择- 要么1个视频，要么9个图片 */
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
    imagePicker.allowPickingType = LFPickingMediaTypeALL;
    imagePicker.maxVideoDuration = 10; /** 10秒视频 */
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
        imagePicker.syncAlbum = YES; /** 实时同步相册 */
    }
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonActionPreviewAsset:(id)sender {
    int limit = 10;
    [[LFAssetManager manager] getCameraRollAlbum:LFPickingMediaTypeALL fetchLimit:limit ascending:YES completion:^(LFAlbum *model) {
        [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingType:LFPickingMediaTypeALL fetchLimit:limit ascending:NO completion:^(NSArray<LFAsset *> *models) {
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
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:[LFCustomObject lf_CustomObjectWithImage:[UIImage imageNamed:@"1.jpeg"]]];
    [array addObject:[LFCustomObject lf_CustomObjectWithImage:[UIImage imageNamed:@"2.jpeg"]]];
    [array addObject:[LFCustomObject lf_CustomObjectWithImage:[UIImage LF_imageWithImagePath:gifPath]]];
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedImageObjects:array index:0 complete:^(NSArray<id<LFAssetImageProtocol>> *photos) {
        [self.thumbnailImageVIew setImage:nil];
        [self.imageView setImage:photos.firstObject.assetImage];
    }];
    imagePicker.imagePickerControllerDidCancelHandle = ^{
        
    };
    /** 全选 */
    imagePicker.selectedAssets = array;
    /** 关闭自动选中 */
    imagePicker.autoSelectCurrentImage = NO;
    imagePicker.supportAutorotate = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonActionPreviewPhoto:(id)sender {
    NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"3" ofType:@"gif"];
    //    [UIImage imageNamed:@"3.gif"] //这样加载是静态图片
    NSMutableArray *array = [NSMutableArray array];
    // 这里测试代码，原图与缩略图为同一张图片，但为了运行流畅性，建议提供缩略图。
    UIImage *image1 = [UIImage imageNamed:@"1.jpeg"];
    [array addObject:[LFPhotoObject lf_PhotoObjectWithImage:image1 thumbnailImage:image1]];
    UIImage *image2 = [UIImage imageNamed:@"2.jpeg"];
    [array addObject:[LFPhotoObject lf_PhotoObjectWithImage:image2 thumbnailImage:image2]];
    [array addObject:[LFPhotoObject lf_PhotoObjectWithImage:[UIImage LF_imageWithImagePath:gifPath] thumbnailImage:[UIImage imageNamed:@"3.gif"]]];
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedPhotoObjects:array complete:^(NSArray<id<LFAssetPhotoProtocol>> *photos) {
        [self.thumbnailImageVIew setImage:photos.firstObject.thumbnailImage];
        [self.imageView setImage:photos.firstObject.originalImage];
    }];
    imagePicker.imagePickerControllerDidCancelHandle = ^{
        
    };
    /** 全选 */
//    imagePicker.selectedAssets = array;
    /** 关闭自动选中 */
    imagePicker.autoSelectCurrentImage = NO;
    imagePicker.supportAutorotate = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonAction4_c_gif:(id)sender {
    self.isCreateGif = YES;
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowPickingType = LFPickingMediaTypePhoto;
    imagePicker.allowTakePicture = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}
- (IBAction)buttonAction5_c_mp4:(id)sender {
    self.isCreateMP4 = YES;
    
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowPickingType = LFPickingMediaTypePhoto;
    imagePicker.allowTakePicture = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - LFImagePickerControllerDelegate
- (void)lf_imagePickerController:(LFImagePickerController *)picker takePhotoHandler:(lf_takePhotoHandler)handler
{
    self.handler = handler;
    
    BOOL onlyPhoto = NO;
    BOOL onlyVideo = NO;
    if (picker.selectedObjects.count) {
        onlyPhoto = picker.maxImagesCount != picker.maxVideosCount && picker.selectedObjects.firstObject.type == LFAssetMediaTypePhoto;
        onlyVideo = picker.maxImagesCount != picker.maxVideosCount && picker.selectedObjects.firstObject.type == LFAssetMediaTypeVideo;
    }
    
    UIImagePickerController *mediaPickerController = [[UIImagePickerController alloc] init];
    // set appearance / 改变相册选择页的导航栏外观
    {
        mediaPickerController.navigationBar.barTintColor = picker.navigationBar.barTintColor;
        mediaPickerController.navigationBar.tintColor = picker.navigationBar.tintColor;
        NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
        UIBarButtonItem *barItem;
        if (@available(iOS 9.0, *)){
            barItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            barItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        textAttrs[NSForegroundColorAttributeName] = picker.barItemTextColor;
        textAttrs[NSFontAttributeName] = picker.barItemTextFont;
        [barItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    }
    mediaPickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    mediaPickerController.delegate = self;
    
    NSMutableArray *mediaTypes = [NSMutableArray array];
    
    if (picker.allowPickingType & LFPickingMediaTypePhoto && picker.selectedObjects.count < picker.maxImagesCount && !onlyVideo) {
        [mediaTypes addObject:(NSString *)kUTTypeImage];
    }
    if (picker.allowPickingType & LFPickingMediaTypeVideo && picker.selectedObjects.count < picker.maxVideosCount && !onlyPhoto) {
        [mediaTypes addObject:(NSString *)kUTTypeMovie];
        mediaPickerController.videoMaximumDuration = picker.maxVideoDuration;
    }
    
    mediaPickerController.mediaTypes = mediaTypes;
    
    /** warning：Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates. */
    [picker presentViewController:mediaPickerController animated:YES completion:nil];
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
                [thumnailData writeToFile:[thumbnailFilePath stringByAppendingPathComponent:name] atomically:YES];
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

#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    BOOL hasUsingMedia = NO;
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]){
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        if (chosenImage) {
            hasUsingMedia = YES;
            if (self.handler) {
                self.handler(chosenImage, (NSString *)kUTTypeImage, ^(LFImagePickerController *picker, NSError * _Nullable error) {
                    [picker dismissViewControllerAnimated:YES completion:^{
                        if (error) {
                            [picker showAlertWithTitle:nil message:error.localizedDescription complete:nil];
                        }
                    }];
                });
            }
        }
    } else if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            hasUsingMedia = YES;
            if (self.handler) {
                self.handler(videoUrl, (NSString *)kUTTypeMovie, ^(LFImagePickerController *picker, NSError * _Nullable error) {
                    [picker dismissViewControllerAnimated:YES completion:^{
                        if (error) {
                            [picker showAlertWithTitle:nil message:error.localizedDescription complete:nil];
                        }
                    }];
                });
            }
        }
    }
    
    self.handler = nil;
    if (!hasUsingMedia) {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
