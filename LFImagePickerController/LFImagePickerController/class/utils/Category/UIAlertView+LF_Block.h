//
//  UIAlertView+Block.h
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/4/3.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^lf_AlertViewBlock)(UIAlertView *alertView, NSInteger buttonIndex);
typedef void (^lf_AlertViewDidShowBlock)(void);

@interface UIAlertView (LF_Block)
//需要自定义初始化方法，调用Block
/** block回调代理 */
- (id)lf_initWithTitle:(NSString *)title
               message:(NSString *)message
     cancelButtonTitle:(NSString *)cancelButtonTitle
     otherButtonTitles:(NSString*)otherButtonTitles
                 block:(lf_AlertViewBlock)block;

/** block回调代理 弹出后回调 */
- (id)lf_initWithTitle:(NSString *)title
               message:(NSString *)message
     cancelButtonTitle:(NSString *)cancelButtonTitle
     otherButtonTitles:(NSString*)otherButtonTitles
                 block:(lf_AlertViewBlock)block
          didShowBlock:(lf_AlertViewDidShowBlock)didShowBlock;

/** block回调代理 文字左对齐 */
- (id)lf_initWithTitle:(NSString *)title
           leftMessage:(NSString *)message
     cancelButtonTitle:(NSString *)cancelButtonTitle
     otherButtonTitles:(NSString*)otherButtonTitles
                 block:(lf_AlertViewBlock)block;

@end
