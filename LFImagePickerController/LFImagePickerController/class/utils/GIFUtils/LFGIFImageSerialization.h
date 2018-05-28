//
//  LFGIFImageSerialization.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

extern __attribute__((overloadable)) NSData * LF_UIImageGIFRepresentation(UIImage *image);

extern __attribute__((overloadable)) NSData * LF_UIImageGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error);

extern __attribute__((overloadable)) NSData * LF_UIImagePNGRepresentation(UIImage *image, CGFloat compressionQuality);

extern __attribute__((overloadable)) NSData * LF_UIImageJPEGRepresentation(UIImage *image, CGFloat compressionQuality);

extern __attribute__((overloadable)) NSData * LF_UIImageRepresentation(UIImage *image, CGFloat compressionQuality, CFStringRef __nonnull type, NSError * __autoreleasing *error);
