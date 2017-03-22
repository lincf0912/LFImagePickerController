//
//  LFTextBarController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"

@protocol LFTextBarControllerDelegate;

@interface LFTextBarController : LFBaseViewController

/** 需要显示的文字 */
@property (nonatomic, copy) NSString *showText;

/** 样式 */
@property (nonatomic, copy) UIColor *oKButtonTitleColorNormal;

/** 代理 */
@property (nonatomic, weak) id<LFTextBarControllerDelegate> delegate;

@end

@protocol LFTextBarControllerDelegate <NSObject>

/** 完成回调 */
- (void)lf_textBarController:(LFTextBarController *)textBar didFinishText:(NSString *)text;
/** 取消回调 */
- (void)lf_textBarControllerDidCancel:(LFTextBarController *)textBar;

@end
