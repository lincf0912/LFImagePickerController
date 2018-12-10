//
//  LFResultObject__property.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultObject.h"
#import "LFResultImage.h"
#import "LFResultVideo.h"

@interface LFResultObject ()

/** PHAsset or ALAsset 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象 */
@property (nonatomic, strong) id asset;
/** 详情 */
@property (nonatomic, strong) LFResultInfo *info;
/** 错误 */
@property (nonatomic, strong) NSError *error;

@end


@interface LFResultImage ()

/** 缩略图 */
@property (nonatomic, strong) UIImage *thumbnailImage;
/** 缩略图数据 */
@property (nonatomic, strong) NSData *thumbnailData;
/** 原图／标清图 */
@property (nonatomic, strong) UIImage *originalImage;
/** 原图／标清图数据 */
@property (nonatomic, strong) NSData *originalData;

/** 子类型 */
@property (nonatomic, assign) LFImagePickerSubMediaType subMediaType;

@end


@interface LFResultVideo ()

/** 封面图片 */
@property (nonatomic, strong) UIImage *coverImage;
/** 视频数据 */
@property (nonatomic, strong) NSData *data;
/** 视频地址 */
@property (nonatomic, strong) NSURL *url;
/** 视频时长 */
@property (nonatomic, assign) NSTimeInterval duration;

@end

@interface LFResultInfo ()

/** 名称 */
@property (nonatomic, copy) NSString *name;
/** 大小［长、宽］ */
@property (nonatomic, assign) CGSize size;
/** 大小［字节］ */
@property (nonatomic, assign) CGFloat byte;

@end
