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
    UIImage* image = nil;
    //1.开启上下文
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0);
    //2.绘制图层
    [self.layer renderInContext: UIGraphicsGetCurrentContext()];
    //3.从上下文中获取新图片
    image = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭图形上下文
    UIGraphicsEndImageContext();
    
    if (image != nil)
    {
        return image;
    }
    
    return nil;
}

@end
