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
    
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //2.绘制图层
    [self.layer renderInContext: context];
    //3.从上下文中获取新图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    
    if (!CGRectEqualToRect(CGRectZero, rect)) {
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        [image drawAtPoint:CGPointMake(-rect.origin.x, -rect.origin.y)];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    
    return image;
}
@end
