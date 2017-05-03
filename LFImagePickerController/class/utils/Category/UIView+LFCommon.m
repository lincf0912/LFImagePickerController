//
//  UIView+LFCommon.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "UIView+LFCommon.h"

@implementation UIView (LFCommon)

- (UIImage *)captureImage
{
    return [self captureImageAtFrame:CGRectZero];
}

- (UIImage *)captureImageAtFrame:(CGRect)rect
{
    UIImage* image = nil;
    
    CGSize size = self.frame.size;
    
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //2.绘制图层
    [self.layer renderInContext: context];
    //3.从上下文中获取新图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    
    if (!CGRectEqualToRect(CGRectZero, rect)) {
        CGSize imageSize = CGSizeMake(floorf(rect.size.width), floorf(rect.size.height));
        UIGraphicsBeginImageContextWithOptions(imageSize, YES, [UIScreen mainScreen].scale);
        [image drawAtPoint:CGPointMake(-ceilf(rect.origin.x), -ceilf(rect.origin.y))];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}
@end
