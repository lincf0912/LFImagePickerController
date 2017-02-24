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

#define bundleImageNamed(name) [UIImage imageNamed:[NSString stringWithFormat:@"LFImagePickerController.bundle/%@", name]]

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
