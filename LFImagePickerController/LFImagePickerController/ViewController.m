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

@interface ViewController () <LFImagePickerControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageVIew;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) AVPlayerLayer *playerLayer;

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


- (IBAction)buttonAction1:(id)sender {
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePicker.allowTakePicture = NO;
//    imagePicker.sortAscendingByCreateDate = NO;
    imagePicker.doneBtnTitleStr = @"发送";
//    imagePicker.allowEditing = NO;
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
//    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
//    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingGif = YES; /** 支持GIF */
    imagePicker.allowPickingLivePhoto = YES; /** 支持Live Photo */
//    imagePicker.autoSelectCurrentImage = NO; /** 关闭自动选中 */
//    imagePicker.defaultAlbumName = @"123"; /** 指定默认显示相册 */
    [self presentViewController:imagePicker animated:YES completion:nil];
    
}

- (IBAction)buttonAction2:(id)sender {
    int limit = 10;
    [[LFAssetManager manager] getCameraRollAlbum:NO allowPickingImage:YES fetchLimit:limit ascending:YES completion:^(LFAlbum *model) {
        [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES fetchLimit:limit ascending:NO completion:^(NSArray<LFAsset *> *models) {
            NSMutableArray *array = [@[] mutableCopy];
            for (LFAsset *asset in models) {
                [array addObject:asset.asset];
            }
            LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedAssets:array index:6 excludeVideo:YES];
            imagePicker.pickerDelegate = self;
//            imagePicker.allowPickingGif = YES; /** 支持GIF */
            /** 全选 */
//            imagePicker.selectedAssets = array;
            
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    }];
}

- (IBAction)buttonAction3:(id)sender {
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
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingResult:(NSArray <LFResultObject /* <LFResultImage/LFResultVideo> */*> *)results;
{
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
                //            [originalData writeToFile:[originalFilePath stringByAppendingPathComponent:name] atomically:YES];
                
                NSLog(@"⚠️Info name:%@ -- infoLength:%fK -- thumnailSize:%fK -- originalSize:%fK -- infoSize:%@", name, byte/1000.0, thumnailData.length/1000.0, originalData.length/1000.0, NSStringFromCGSize(size));
                
                NSLog(@"🎉thumbnail_imageOrientation:%ld -- original_imageOrientation:%ld -- thumbnailData_imageOrientation:%ld -- originalData_imageOrientation:%ld", (long)thumbnailImage.imageOrientation, (long)originalImage.imageOrientation, [UIImage imageWithData:thumnailData scale:[UIScreen mainScreen].scale].imageOrientation, [UIImage imageWithData:originalData scale:[UIScreen mainScreen].scale].imageOrientation);
            }
            
        } else if ([result isKindOfClass:[LFResultVideo class]]) {
            
            LFResultVideo *resultVideo = (LFResultVideo *)result;
            if (playerLayer.player == nil && originalImage == nil) {
                /** 保存视频 */
                [resultVideo.data writeToFile:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name] atomically:YES];
                
                thumbnailImage = resultVideo.coverImage;
                
                AVPlayer *player = [AVPlayer playerWithURL:[NSURL fileURLWithPath:[originalFilePath stringByAppendingPathComponent:resultVideo.info.name]]];
                [playerLayer setPlayer:player];
                [player play];
            }
        }
    }
    
    [self.thumbnailImageVIew setImage:thumbnailImage];
    [self.imageView setImage:originalImage];

}

@end
