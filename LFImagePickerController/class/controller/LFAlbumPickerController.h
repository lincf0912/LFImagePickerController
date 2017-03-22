//
//  LFAlbumPickerController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"
@class LFAlbum;
@interface LFAlbumPickerController : LFBaseViewController

/** 首次替换对象 */
@property (nonatomic, setter=setReplaceModel:) LFAlbum *replaceModel;
@end
