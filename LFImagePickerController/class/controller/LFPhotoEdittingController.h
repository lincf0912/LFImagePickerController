//
//  LFPhotoEdittingController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"
#import "LFPhotoEdit.h"

@protocol LFPhotoEdittingControllerDelegate;

@interface LFPhotoEdittingController : LFBaseViewController
/** 设置编辑图片->重新初始化 */
@property (nonatomic, strong) UIImage *editImage;
/** 设置编辑对象->重新编辑 */
@property (nonatomic, strong) LFPhotoEdit *photoEdit;

/** 代理 */
@property (nonatomic, weak) id<LFPhotoEdittingControllerDelegate> delegate;

@end

@protocol LFPhotoEdittingControllerDelegate <NSObject>

- (void)lf_PhotoEdittingController:(LFPhotoEdittingController *)photoEdittingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit;
- (void)lf_PhotoEdittingController:(LFPhotoEdittingController *)photoEdittingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit;

@end
