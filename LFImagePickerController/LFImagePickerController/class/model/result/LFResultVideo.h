//
//  LFResultVideo.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultObject.h"

@interface LFResultVideo : LFResultObject

/** 封面图片 */
@property (nonatomic, readonly) UIImage *coverImage;
/** 视频数据 */
@property (nonatomic, readonly) NSData *data;
/** 视频地址 */
@property (nonatomic, readonly) NSURL *url;
/** 视频时长 */
@property (nonatomic, assign, readonly) NSTimeInterval duration;

@end
