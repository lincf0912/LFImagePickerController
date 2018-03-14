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

#define iOS7Later ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
#define iOS9_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)

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

#define LF_StatusBarHeight (CGRectGetWidth([UIScreen mainScreen].bounds) < CGRectGetHeight([UIScreen mainScreen].bounds) ? 20 : 0)
#define LF_StatusBarHeight_iOS11 (self.view.safeAreaInsets.top > 0 ? self.view.safeAreaInsets.top : (CGRectGetWidth([UIScreen mainScreen].bounds) < CGRectGetHeight([UIScreen mainScreen].bounds) ? 20 : 0))

/** 标清图压缩大小 */
extern float const kCompressSize;
/** 缩略图压缩大小 */
extern float const kThumbnailCompressSize;
/** 图片最大大小 */
extern float const kMaxPhotoBytes;
/** 视频最大时长 */
extern float const kMaxVideoDurationze;

/** 图片压缩系数 */
extern float const kimageCompressionFactor;


@interface LFImagePickerHeader : NSObject

@end
