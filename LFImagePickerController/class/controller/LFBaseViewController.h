//
//  LFBaseViewController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFBaseViewController : UIViewController

/** 是否隐藏导航栏 默认NO */
@property (nonatomic, assign) BOOL isHiddenNavBar;

/** 是否隐藏状态 默认NO */
@property (nonatomic, assign) BOOL isHiddenStatusBar;

/** 导航栏高度+状态栏 */
- (CGFloat)navigationHeight;
/** 不计算导航栏的屏幕大小 */
- (CGRect)viewFrameWithoutNavigation;
@end
