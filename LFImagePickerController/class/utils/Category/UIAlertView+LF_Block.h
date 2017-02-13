//
//  UIAlertView+Block.h
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/4/3.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^AlertViewBlock)(UIAlertView *alertView, NSInteger buttonIndex);
typedef void (^AlertViewDidShowBlock)();

@interface UIAlertView (LF_Block)
//需要自定义初始化方法，调用Block
/** block回调代理 */
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString*)otherButtonTitles
              block:(AlertViewBlock)block;

/** block回调代理 弹出后回调 */
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString*)otherButtonTitles
              block:(AlertViewBlock)block
       didShowBlock:(AlertViewDidShowBlock)didShowBlock;

/** block回调代理 文字左对齐 */
- (id)initWithTitle:(NSString *)title
        leftMessage:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString*)otherButtonTitles
              block:(AlertViewBlock)block;

@end
