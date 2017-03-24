//
//  LFImagePickerHeader.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

#define iOS7Later ([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)
#define iOS8Later ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f)
#define iOS9Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.0f)
#define iOS9_1Later ([UIDevice currentDevice].systemVersion.floatValue >= 9.1f)


#define dispatch_main_async_safe(block)\
if ([NSThread isMainThread]) {\
block();\
} else {\
dispatch_async(dispatch_get_main_queue(), block);\
}

#define dispatch_globalQueue_async_safe(block)\
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);



#define bundleImageNamed(name) [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", kBundlePath, name]]
#define bundleEditImageNamed(name) [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", kEditPath, name]]
#define bundleStickerImageNamed(name) [UIImage imageNamed:[NSString stringWithFormat:@"%@/%@", kStickersPath, name]]

extern NSString *const kBundlePath;
/** 编辑资源路径 */
extern NSString *const kEditPath;
/** 贴图资源路径 */
extern NSString *const kStickersPath;



/**
 *  NSString;
 */
extern NSString *const kImageInfoFileName;     // 图片名称
/**
 *  NSValue; CGSize size;[value getValue:&size];
 */
extern NSString *const kImageInfoFileSize;     // 图片大小［长、宽］
/**
 *  NSNumber;
 */
extern NSString *const kImageInfoFileByte;     // 图片大小［字节］


@interface LFImagePickerHeader : NSObject

@end
