//
//  ViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "ViewController.h"
#import "LFImagePickerController.h"

#import "LFAssetManager.h"

@interface ViewController () <LFImagePickerControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
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
    
    imagePicker.allowTakePicture = NO;
    //    imagePicker.sortAscendingByCreateDate = NO;
    imagePicker.doneBtnTitleStr = @"发送";
    //    imagePicker.allowEditting = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)buttonAction2:(id)sender {
    [[LFAssetManager manager] getCameraRollAlbum:NO allowPickingImage:YES fetchLimit:2 ascending:YES completion:^(LFAlbum *model) {
        [[LFAssetManager manager] getAssetsFromFetchResult:model.result allowPickingVideo:NO allowPickingImage:YES fetchLimit:2 ascending:NO completion:^(NSArray<LFAsset *> *models) {
            NSMutableArray *array = [@[] mutableCopy];
            for (LFAsset *asset in models) {
                [array addObject:asset.asset];
            }
            LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedAssets:array index:0 excludeVideo:YES];
            imagePicker.pickerDelegate = self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    }];
}

- (IBAction)buttonAction3:(id)sender {
    NSArray *array = @[[UIImage imageNamed:@"1.jpeg"], [UIImage imageNamed:@"2.jpeg"]];
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithSelectedPhotos:array index:0 complete:^(NSArray *photos) {
        
    }];
    /** 全选 */
//    imagePicker.selectedAssets = array;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

@end
