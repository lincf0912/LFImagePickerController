//
//  LFResultInfo.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFResultInfo : NSObject

/** 名称 */
@property (nonatomic, copy, readonly) NSString *name;
/** 大小［长、宽］ */
@property (nonatomic, assign, readonly) CGSize size;
/** 大小［字节］ */
@property (nonatomic, assign, readonly) CGFloat byte;

@end
