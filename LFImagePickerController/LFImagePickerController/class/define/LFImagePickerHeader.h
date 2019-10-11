//
//  LFImagePickerHeader.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFImagePickerPublicHeader.h"
#import "NSBundle+LFImagePicker.h"

#define isiPhone (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define isiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#define dispatch_globalQueue_async_safe(block)\
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);


#define bundleImageNamed(name) [NSBundle lf_imageNamed:name]

/** 视频时间（取整：四舍五入） */
extern NSTimeInterval lf_videoDuration(NSTimeInterval duration);
/** 是否长图 */
extern BOOL lf_isPiiic(CGSize imageSize);
/** 是否横图 */
extern BOOL lf_isHor(CGSize imageSize);

/** 标清图压缩大小 */
extern float const kCompressSize;
/** 缩略图压缩大小 */
extern float const kThumbnailCompressSize;
/** 图片最大大小 */
extern float const kMaxPhotoBytes;
/** 视频最大时长 */
extern float const kMaxVideoDurationze;

