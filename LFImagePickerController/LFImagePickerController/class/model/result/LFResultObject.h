//
//  LFResultObject.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFResultInfo.h"

@interface LFResultObject : NSObject

/** PHAsset or ALAsset 如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象 */
@property (nonatomic, readonly) id asset;
/** 详情 */
@property (nonatomic, readonly) LFResultInfo *info;
/** 错误 */
@property (nonatomic, readonly) NSError *error;

+ (LFResultObject *)errorResultObject:(id)asset;
@end
