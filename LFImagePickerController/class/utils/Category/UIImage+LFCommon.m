//
//  UIImage+LFCommon.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "UIImage+LFCommon.h"

@implementation UIImage (LFCommon)

- (UIImage *)fixOrientation {
    
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    CGImageRef cgimg = [self cgFixOrientation];
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGImageRelease(cgimg);
    return img;
}

- (CGImageRef)cgFixOrientation {
    // No-op if the orientation is already correct
    
    UIImage *editImg = self;//[UIImage imageWithData:UIImagePNGRepresentation(self)];
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = [UIImage exchangeOrientation:editImg.imageOrientation size:editImg.size];
    
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, editImg.size.width, editImg.size.height,
                                             CGImageGetBitsPerComponent(editImg.CGImage), 0,
                                             CGImageGetColorSpace(editImg.CGImage),
                                             CGImageGetBitmapInfo(editImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (editImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0, editImg.size.height, editImg.size.width), editImg.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0, editImg.size.width, editImg.size.height), editImg.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    
    CGContextRelease(ctx);
    
    return cgimg;
}

+ (CGAffineTransform)exchangeOrientation:(UIImageOrientation)imageOrientation size:(CGSize)size
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default:
            break;
    }
    
    switch (imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default:
            break;
    }
    
    return transform;
}


- (UIImage *)scaleToSize:(CGSize)size {
    if (self.size.width > size.width) {
        UIGraphicsBeginImageContext(size);
        [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    } else {
        return self;
    }
}
@end
