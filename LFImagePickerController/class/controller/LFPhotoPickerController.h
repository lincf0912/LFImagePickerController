//
//  LFPhotoPickerController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LFAlbum;

@interface LFPhotoPickerController : UIViewController

@property (nonatomic, strong) LFAlbum *model;
/** 拍照回调 */
@property (nonatomic, copy) void (^takePhotoHandle)();

@end
