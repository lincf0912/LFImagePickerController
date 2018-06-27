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
- (UIImage *)lf_fixOrientation;

/** 根据图片大小和设置的最大宽度，返回缩放后的大小 */
+ (CGSize)lf_imageSizeBySize:(CGSize)size maxWidth:(CGFloat)maxWidth;

/** 计算图片的缩放大小 */
+ (CGSize)lf_scaleImageSizeBySize:(CGSize)imageSize targetSize:(CGSize)size isBoth:(BOOL)isBoth;

/** 缩放图片到指定大小 */
- (UIImage*)lf_scaleToSize:(CGSize)size;

/** 合并图片与文字 */
+ (UIImage *)lf_mergeImage:(UIImage *)image text:(NSString *)text;

/*
 *转换成马赛克,level代表一个点转为多少level*level的正方形
 */
- (UIImage *)lf_transToMosaicLevel:(NSUInteger)level;

/** 高斯模糊 */
- (UIImage *)lf_transToBlurLevel:(NSUInteger)blurRadius;
@end
