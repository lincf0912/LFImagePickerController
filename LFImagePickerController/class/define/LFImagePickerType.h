//
//  LFImagePickerEdittingType.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#ifndef LFImagePickerEdittingType_h
#define LFImagePickerEdittingType_h

typedef NS_ENUM(NSUInteger, LFPhotoEdittingType) {
    /** 绘画 */
    LFPhotoEdittingType_draw = 0,
    /** 贴图 */
    LFPhotoEdittingType_sticker,
    /** 文本 */
    LFPhotoEdittingType_text,
    /** 模糊 */
    LFPhotoEdittingType_splash,
    /** 修剪 */
    LFPhotoEdittingType_crop,
};

#endif /* LFImagePickerEdittingType_h */
