//
//  LFPhotoPickerController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"
@class LFAlbum,LFPhotoPreviewController;

@interface LFPhotoPickerController : LFBaseViewController

@property (nonatomic, strong) LFAlbum *model;

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc;

@end
