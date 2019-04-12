//
//  LFGIFImageSerialization.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

extern __attribute__((overloadable)) NSData * _Nullable LF_UIImageGIFRepresentation(UIImage * _Nonnull image);

extern __attribute__((overloadable)) NSData * _Nullable LF_UIImageGIFRepresentation(UIImage * _Nonnull image, NSTimeInterval duration, NSUInteger loopCount, NSError * _Nullable __autoreleasing * _Nullable error);

extern __attribute__((overloadable)) NSData * _Nullable LF_UIImagePNGRepresentation(UIImage * _Nonnull image, CGFloat compressionQuality);

extern __attribute__((overloadable)) NSData * _Nullable LF_UIImageJPEGRepresentation(UIImage * _Nonnull image, CGFloat compressionQuality);

extern __attribute__((overloadable)) NSData * _Nullable LF_UIImageRepresentation(UIImage * _Nonnull image, CGFloat compressionQuality, CFStringRef __nonnull type, NSError * _Nullable __autoreleasing * _Nullable error);
