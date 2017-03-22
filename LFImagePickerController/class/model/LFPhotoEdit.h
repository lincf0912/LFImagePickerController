//
//  LFPhotoEdit.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFPhotoEdit : NSObject

/** 编辑封面 */
@property (nonatomic, readonly) UIImage *editPosterImage;
/** 编辑图片 */
@property (nonatomic, readonly) UIImage *editPreviewImage;
/** 是否有效->有编辑过 */
@property (nonatomic, readonly) BOOL isWork;
/** 是否有改变编辑 */
@property (nonatomic, readonly) BOOL isChanged;

@end
