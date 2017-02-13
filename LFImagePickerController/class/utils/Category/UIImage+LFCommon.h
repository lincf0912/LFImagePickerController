//
//  UIImage+LFCommon.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (LFCommon)

/** 修正图片方向 */
- (UIImage *)fixOrientation;
/** 缩放图片 */
- (UIImage *)scaleToSize:(CGSize)size;


@end
