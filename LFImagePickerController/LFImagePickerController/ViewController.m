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


- (IBAction)buttonAction1:(id)sender {
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePicker.allowTakePicture = NO;
//    imagePicker.sortAscendingByCreateDate = NO;
    imagePicker.doneBtnTitleStr = @"发送";
//    imagePicker.allowEditting = NO;
    imagePicker.supportAutorotate = YES; /** 适配横屏 */
//    imagePicker.imageCompressSize = 200; /** 标清图压缩大小 */
//    imagePicker.thumbnailCompressSize = 20; /** 缩略图压缩大小 */
    imagePicker.allowPickingGif = YES; /** 支持GIF */
    imagePicker.allowPickingLivePhoto = YES; /** 支持Live Photo */
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

- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingThumbnailImages:(NSArray<UIImage *> *)thumbnailImages originalImages:(NSArray<UIImage *> *)originalImages infos:(NSArray<NSDictionary *> *)infos
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
    
    for (NSInteger i = 0; i < originalImages.count; i++) {
        UIImage *thumbnailImage = thumbnailImages[i];
        UIImage *image = originalImages[i];
        NSDictionary *info = infos[i];
        NSString *name = info[kImageInfoFileName];
        NSData *thumnailData = info[kImageInfoFileThumbnailData];
        NSData *originalData =info[kImageInfoFileOriginalData];
        CGFloat byte = [info[kImageInfoFileByte] floatValue];
        CGSize size = [info[kImageInfoFileSize] CGSizeValue];
        
        
        /** 缩略图保存到路径 */
//        [UIImageJPEGRepresentation(thumbnailImage, 0.5f) writeToFile:[thumbnailFilePath stringByAppendingPathComponent:name] atomically:YES];
        [thumnailData writeToFile:[thumbnailFilePath stringByAppendingPathComponent:name] atomically:YES];
        /** 原图保存到路径 */
//        [UIImageJPEGRepresentation(image, 0.5f) writeToFile:[originalFilePath stringByAppendingPathComponent:name] atomically:YES];
        [originalData writeToFile:[originalFilePath stringByAppendingPathComponent:name] atomically:YES];
        
        NSLog(@"⚠️Info name:%@ -- infoLength:%fK -- thumnailSize:%fK -- originalSize:%fK -- infoSize:%@", name, byte/1000.0, thumnailData.length/1000.0, originalData.length/1000.0, NSStringFromCGSize(size));
        
        NSLog(@"🎉thumbnail_imageOrientation:%ld -- original_imageOrientation:%ld -- thumbnailData_imageOrientation:%ld -- originalData_imageOrientation:%ld", (long)thumbnailImage.imageOrientation, (long)image.imageOrientation, [UIImage imageWithData:thumnailData scale:[UIScreen mainScreen].scale].imageOrientation, [UIImage imageWithData:originalData scale:[UIScreen mainScreen].scale].imageOrientation);
    }
    
    [self.thumbnailImageVIew setImage:thumbnailImages.firstObject];
    [self.imageView setImage:originalImages.firstObject];
}

@end
