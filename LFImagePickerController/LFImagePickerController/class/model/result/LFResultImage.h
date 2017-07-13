//
//  LFResultImage.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultObject.h"
#import "LFImagePickerPublicHeader.h"

@interface LFResultImage : LFResultObject

/** 缩略图 */
@property (nonatomic, readonly) UIImage *thumbnailImage;
/** 缩略图数据 */
@property (nonatomic, readonly) NSData *thumbnailData;
/** 原图／标清图 */
@property (nonatomic, readonly) UIImage *originalImage;
/** 原图／标清图数据 */
@property (nonatomic, readonly) NSData *originalData;

/** 子类型 */
@property (nonatomic, assign, readonly) LFImagePickerSubMediaType subMediaType;

@end
