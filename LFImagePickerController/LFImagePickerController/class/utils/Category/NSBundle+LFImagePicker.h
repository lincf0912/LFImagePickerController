//
//  NSBundle+LFImagePicker.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2018/3/14.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSBundle (LFImagePicker)

+ (instancetype)lf_imagePickerBundle;
+ (UIImage *)lf_imageNamed:(NSString *)name;
+ (NSString *)lf_localizedStringForKey:(NSString *)key;
+ (NSString *)lf_localizedStringForKey:(NSString *)key value:(NSString *)value;

@end
