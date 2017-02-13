//
//  UIAlertView+Block.m
//  MiracleMessenger
//
//  Created by LamTsanFeng on 15/4/3.
//  Copyright (c) 2015年 Anson. All rights reserved.
//

#import "UIAlertView+LF_Block.h"
#import <objc/runtime.h>

static char overAlertViewKey;
static char overAlertViewKeyLeft;
static char overAlertViewKeyDidShow;

@implementation UIAlertView (LF_Block)

/** block回调代理 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles block:(AlertViewBlock)block
{
    return [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles block:block didShowBlock:nil];
}

/** block回调代理 弹出后回调 */
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString*)otherButtonTitles block:(AlertViewBlock)block didShowBlock:(AlertViewDidShowBlock)didShowBlock
{
    objc_setAssociatedObject(self, &overAlertViewKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &overAlertViewKeyDidShow, didShowBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    return [self initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];//注意这里初始化父类的
}

/** block回调代理 文字左对齐 */
- (id)initWithTitle:(NSString *)title
        leftMessage:(NSString *)message
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString*)otherButtonTitles
              block:(AlertViewBlock)block
{
    objc_setAssociatedObject(self, &overAlertViewKeyLeft, @(YES), OBJC_ASSOCIATION_ASSIGN);
    return [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles block:block];
}

#pragma mark - AlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //这里调用函数指针_block(要传进来的参数);
    AlertViewBlock block = (AlertViewBlock)objc_getAssociatedObject(self, &overAlertViewKey);
    if (block) {
        block(alertView, buttonIndex);
        objc_setAssociatedObject(self, &overAlertViewKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(self, &overAlertViewKeyLeft, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(self, &overAlertViewKeyDidShow, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    BOOL isCenter = [((NSNumber *)objc_getAssociatedObject(self, &overAlertViewKeyLeft)) boolValue];
    if (isCenter == NO) return;
    if (([UIDevice currentDevice].systemVersion.floatValue >= 7.0f)) {
        
        NSString *message = alertView.message;
//        CGFloat margin = 20;
//        CGSize size = [message boundingRectWithSize:CGSizeMake(240-2*margin,400) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading|NSStringDrawingUsesDeviceMetrics|NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]} context:nil].size;
//        UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(margin, 0,240, size.height)];
//        textLabel.font = [UIFont systemFontOfSize:14];
//        textLabel.textColor = [UIColor blackColor];
//        textLabel.backgroundColor = [UIColor clearColor];
//        textLabel.lineBreakMode =NSLineBreakByWordWrapping;
//        textLabel.numberOfLines =0;
//        textLabel.textAlignment =NSTextAlignmentLeft;
//        textLabel.text = message;
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, -20, 240, size.height+margin)];
//        [view addSubview:textLabel];
        UIView *view = [self createView:message];
        [alertView setValue:view forKey:@"accessoryView"];
        
        alertView.message = @"";
    } else {
        NSInteger count = 0;
        for( UIView * view in alertView.subviews )
        {
            if( [view isKindOfClass:[UILabel class]] )
            {
                count ++;
                if ( count == 2 ) { //仅对message左对齐
                    UILabel* label = (UILabel*) view;
                    label.textAlignment =NSTextAlignmentLeft;
                }
            }
        }
    }
}

- (void)didPresentAlertView:(UIAlertView *)alertView
{
    AlertViewDidShowBlock block = (AlertViewDidShowBlock)objc_getAssociatedObject(self, &overAlertViewKeyDidShow);
    if (block) {
        block();
    }
}

- (UIView *)createView:(NSString *)message
{
    
    float textWidth = 260;
    
    float textMargin = 10;
    
    UIFont *textFont = [UIFont systemFontOfSize:15];
    
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
    
    attrs[NSFontAttributeName] = textFont;
    
    CGSize maxSize = CGSizeMake(textWidth-textMargin*2, MAXFLOAT);
    
    CGSize size = [message boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
    
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(textMargin, textMargin, textWidth, size.height)];
    
    textLabel.font = textFont;
    
    textLabel.textColor = [UIColor blackColor];
    
    textLabel.backgroundColor = [UIColor clearColor];
    
    textLabel.lineBreakMode =NSLineBreakByWordWrapping;
    
    textLabel.numberOfLines =0;
    
    textLabel.textAlignment =NSTextAlignmentLeft;
    
    textLabel.text = message;
    
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, textWidth + textMargin * 2,CGRectGetMaxY(textLabel.frame)+textMargin)];
    
    [demoView addSubview:textLabel];
    
    return demoView;
    
}

@end
