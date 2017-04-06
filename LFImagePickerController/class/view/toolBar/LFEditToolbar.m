//
//  LFEditToolbar.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFEditToolbar.h"
#import "UIView+LFFrame.h"
#import "LFImagePickerHeader.h"
#import "LFColorSlider.h"

#define mainButtonImageNormals @[@"EditImagePenToolBtn.png", @"EditImageEmotionToolBtn.png", @"EditImageTextToolBtn.png", @"EditImageMosaicToolBtn.png", @"EditImageCropToolBtn.png"]
#define mainButtonImageHighlighted @[@"EditImagePenToolBtn_HL.png", @"EditImageEmotionToolBtn_HL.png", @"EditImageTextToolBtn_HL.png", @"EditImageMosaicToolBtn_HL.png", @"EditImageCropToolBtn_HL.png"]

@interface LFEditToolbar () <LFColorSliderDelegate>

/** 一级菜单 */
@property (nonatomic, weak) UIView *edit_menu;

/** 二级菜单 */
@property (nonatomic, weak) UIView *edit_drawMenu;
@property (nonatomic, weak) UIButton *edit_drawMenu_revoke;
@property (nonatomic, weak) UIView *edit_splashMenu;
@property (nonatomic, weak) UIButton *edit_splashMenu_revoke;

/** 当前激活菜单按钮 */
@property (nonatomic, weak) UIButton *edit_splashMenu_action_button;

/** 当前显示菜单 */
@property (nonatomic, weak) UIView *selectMenu;
/** 当前点击按钮 */
@property (nonatomic, weak) UIButton *selectButton;

/** 绘画拾色器 */
@property (nonatomic, weak) LFColorSlider *draw_colorSlider;

@end

@implementation LFEditToolbar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:(CGRect){{0, [UIScreen mainScreen].bounds.size.height-99}, {[UIScreen mainScreen].bounds.size.width, 99}}];
    if (self) {
        [self customInit];
        
    }
    return self;
}

- (void)customInit
{
    [self mainBar];
    [self subBar];
}

#pragma mark - 菜单创建
- (void)mainBar
{
    UIView *edit_menu = [[UIView alloc] initWithFrame:CGRectMake(0, self.height - 44, self.width, 44)];
    CGFloat rgb = 34 / 255.0;
    edit_menu.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    NSInteger buttonCount = 5;
    
    CGFloat width = CGRectGetWidth(self.frame)/buttonCount;
    for (NSInteger i=0; i<buttonCount; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.frame = CGRectMake(width*i, 0, width, 44);
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        [button setImage:bundleEditImageNamed(mainButtonImageNormals[i]) forState:UIControlStateNormal];
        [button setImage:bundleEditImageNamed(mainButtonImageHighlighted[i]) forState:UIControlStateHighlighted];
        [button setImage:bundleEditImageNamed(mainButtonImageHighlighted[i]) forState:UIControlStateSelected];
        [button addTarget:self action:@selector(edit_toolBar_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [edit_menu addSubview:button];
    }
    
    UIView *divide = [[UIView alloc] init];
    CGFloat rgb2 = 40 / 255.0;
    divide.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];
    divide.frame = CGRectMake(0, 0, self.width, 1);
    
    [edit_menu addSubview:divide];
    self.edit_menu = edit_menu;
    
    [self addSubview:edit_menu];
}

- (void)subBar
{
    [self drawMenu];
    [self splashMenu];
}

#pragma mark - 二级菜单栏(懒加载)
- (void)drawMenu
{
    if (_edit_drawMenu == nil) {
        UIView *edit_drawMenu = [[UIView alloc] initWithFrame:CGRectMake(_edit_menu.x, _edit_menu.y, _edit_menu.width, 55)];
        edit_drawMenu.backgroundColor = _edit_menu.backgroundColor;
        edit_drawMenu.alpha = 0.f;
        /** 添加按钮获取点击 */
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = edit_drawMenu.bounds;
        [edit_drawMenu addSubview:button];
        
        UIButton *edit_drawMenu_revoke = [self revokeButtonWithType:0];
        [edit_drawMenu addSubview:edit_drawMenu_revoke];
        self.edit_drawMenu_revoke = edit_drawMenu_revoke;
        
        /** 分隔线 */
        UIView *separateView = [self separateView];
        separateView.frame = CGRectMake(CGRectGetMinX(edit_drawMenu_revoke.frame)-10*2, (CGRectGetHeight(edit_drawMenu.frame)-25)/2, 1, 25);
        [edit_drawMenu addSubview:separateView];
        
        /** 拾色器 */
        CGFloat sliderHeight = 34.f, margin = 30.f;
        LFColorSlider *_colorSlider = [[LFColorSlider alloc] initWithFrame:CGRectMake(margin, (CGRectGetHeight(edit_drawMenu.frame)-sliderHeight)/2, CGRectGetMinX(separateView.frame)-2*margin, sliderHeight)];
        _colorSlider.delegate = self;
        [edit_drawMenu addSubview:_colorSlider];
        self.draw_colorSlider = _colorSlider;
        
        self.edit_drawMenu = edit_drawMenu;
        
        [self insertSubview:edit_drawMenu belowSubview:_edit_menu];
    }
}

- (void)splashMenu
{
    if (_edit_splashMenu == nil) {
        UIView *edit_splashMenu = [[UIView alloc] initWithFrame:CGRectMake(_edit_menu.x, _edit_menu.y, _edit_menu.width, 55)];
        edit_splashMenu.backgroundColor = _edit_menu.backgroundColor;
        edit_splashMenu.alpha = 0.f;
        /** 添加按钮获取点击 */
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = edit_splashMenu.bounds;
        [edit_splashMenu addSubview:button];
        
        UIButton *edit_splashMenu_revoke = [self revokeButtonWithType:3];
        [edit_splashMenu addSubview:edit_splashMenu_revoke];
        self.edit_splashMenu_revoke = edit_splashMenu_revoke;
        
        /** 分隔线 */
        UIView *separateView = [self separateView];
        separateView.frame = CGRectMake(CGRectGetMinX(edit_splashMenu_revoke.frame)-10*2, (CGRectGetHeight(edit_splashMenu.frame)-25)/2, 1, 25);
        [edit_splashMenu addSubview:separateView];
        
        /** 剩余长度 */
        CGFloat width = CGRectGetMinX(edit_splashMenu_revoke.frame);
        /** 按钮个数 */
        int count = 2;
        /** 平分空间 */
        CGFloat averageWidth = width/(count+1);
        
        UIButton *action1 = [UIButton buttonWithType:UIButtonTypeCustom];
        action1.frame = CGRectMake(averageWidth*1-44/2, (CGRectGetHeight(edit_splashMenu.frame)-30)/2, 44, 30);
        [action1 addTarget:self action:@selector(splashMenu_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [action1 setImage:bundleEditImageNamed(@"EditImageTraditionalMosaicBtn.png") forState:UIControlStateNormal];
        [action1 setImage:bundleEditImageNamed(@"EditImageTraditionalMosaicBtn_HL.png") forState:UIControlStateHighlighted];
        [action1 setImage:bundleEditImageNamed(@"EditImageTraditionalMosaicBtn_HL.png") forState:UIControlStateSelected];
        action1.tag = 30;
        [edit_splashMenu addSubview:action1];
        _edit_splashMenu_action_button = action1;
        
        UIButton *action2 = [UIButton buttonWithType:UIButtonTypeCustom];
        action2.frame = CGRectMake(averageWidth*2-44/2, (CGRectGetHeight(edit_splashMenu.frame)-30)/2, 44, 30);
        [action2 addTarget:self action:@selector(splashMenu_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [action2 setImage:bundleEditImageNamed(@"EditImageBrushMosaicBtn.png") forState:UIControlStateNormal];
        [action2 setImage:bundleEditImageNamed(@"EditImageBrushMosaicBtn_HL.png") forState:UIControlStateHighlighted];
        [action2 setImage:bundleEditImageNamed(@"EditImageBrushMosaicBtn_HL.png") forState:UIControlStateSelected];
        action2.tag = 31;
        [edit_splashMenu addSubview:action2];
        
        /** 优先激活首个按钮 */
        action1.selected = YES;
        
        self.edit_splashMenu = edit_splashMenu;
        [self insertSubview:edit_splashMenu belowSubview:_edit_menu];
    }
}

- (UIButton *)revokeButtonWithType:(NSInteger)type
{
    UIButton *revoke = [UIButton buttonWithType:UIButtonTypeCustom];
    revoke.frame = CGRectMake(_edit_menu.width-44-5, 0, 44, 55);
    [revoke setImage:bundleEditImageNamed(@"EditImageRevokeBtn.png") forState:UIControlStateNormal];
    [revoke setImage:bundleEditImageNamed(@"EditImageRevokeBtn_HL.png") forState:UIControlStateHighlighted];
    [revoke setImage:bundleEditImageNamed(@"EditImageRevokeBtn_HL.png") forState:UIControlStateSelected];
    revoke.tag = type;
    [revoke addTarget:self action:@selector(revoke_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    return revoke;
}

- (UIImageView *)separateView
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:bundleEditImageNamed(@"AlbumCommentLine.png")];
//    imageView.contentMode = UIViewContentModeScaleAspectFit;
    return imageView;
}

#pragma mark - 一级菜单事件(action)
- (void)edit_toolBar_buttonClick:(UIButton *)button
{
    switch (button.tag) {
        case 0:
        {
            [self showMenuView:_edit_drawMenu];
            if (button.isSelected == NO) {
                if ([self.delegate respondsToSelector:@selector(lf_editToolbar:canRevokeAtIndex:)]) {
                    BOOL canRevoke = [self.delegate lf_editToolbar:self canRevokeAtIndex:button.tag];
                    _edit_drawMenu_revoke.enabled = canRevoke;
                }
            }
            [self changedButton:button];
        }
            break;
        case 3:
        {
            [self showMenuView:_edit_splashMenu];
            if (button.isSelected == NO) {
                if ([self.delegate respondsToSelector:@selector(lf_editToolbar:canRevokeAtIndex:)]) {
                    BOOL canRevoke = [self.delegate lf_editToolbar:self canRevokeAtIndex:button.tag];
                    _edit_splashMenu_revoke.enabled = canRevoke;
                }
            }
            [self changedButton:button];
        }
            break;
        default:
            break;
    }
    if ([self.delegate respondsToSelector:@selector(lf_editToolbar:mainDidSelectAtIndex:)]) {
        [self.delegate lf_editToolbar:self mainDidSelectAtIndex:button.tag];
    }
}

#pragma mark - 二级菜单撤销（action）
- (void)revoke_buttonClick:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(lf_editToolbar:subDidRevokeAtIndex:)]) {
        [self.delegate lf_editToolbar:self subDidRevokeAtIndex:button.tag];
    }
    if ([self.delegate respondsToSelector:@selector(lf_editToolbar:canRevokeAtIndex:)]) {
        BOOL canRevoke = [self.delegate lf_editToolbar:self canRevokeAtIndex:button.tag];
        button.enabled = canRevoke;
    }
}

- (void)splashMenu_buttonClick:(UIButton *)button
{
    if (_edit_splashMenu_action_button != button) {
        _edit_splashMenu_action_button.selected = NO;
        button.selected = YES;
        _edit_splashMenu_action_button = button;
        if ([self.delegate respondsToSelector:@selector(lf_editToolbar:subDidSelectAtIndex:)]) {
            NSString *tag = [NSString stringWithFormat:@"%ld", (long)button.tag];
            NSInteger row = [[tag substringFromIndex:1] integerValue];
            NSInteger section = [[tag substringToIndex:1] integerValue];
            [self.delegate lf_editToolbar:self subDidSelectAtIndex:[NSIndexPath indexPathForRow:row inSection:section]];
        }
    }
}

#pragma mark - 显示二级菜单栏
- (void)showMenuView:(UIView *)menu
{
    /** 将显示的菜单先关闭 */
    if (_selectMenu) {
        [self hidenMenuView];
    }
    if (_selectMenu != menu) {
        /** 显示新菜单 */
        _selectMenu = menu;
        [UIView animateWithDuration:0.25f animations:^{
            menu.y = 0;
            menu.alpha = 1.f;
        }];
    } else {
        _selectMenu = nil;
    }
}
- (void)hidenMenuView
{
    [self sendSubviewToBack:_selectMenu];
    [UIView animateWithDuration:0.25f animations:^{
        _selectMenu.y = _edit_menu.y;
        _selectMenu.alpha = 0.f;
    }];
}

#pragma mark - 按钮激活切换
- (BOOL)changedButton:(UIButton *)button
{
    /** 选中按钮 */
    button.selected = !button.selected;
    if (_selectButton != button) {
        _selectButton.selected = !_selectButton.selected;
        _selectButton = button;
    } else {
        _selectButton = nil;
    }
    return (_selectButton != nil);
}

/** 当前激活主菜单 */
- (NSUInteger)mainSelectAtIndex
{
    return _selectButton ? _selectButton.tag : -1;
}

/** 允许撤销 */
- (void)setRevokeAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
        {
            _edit_drawMenu_revoke.enabled = YES;
        }
            break;
        case 3:
        {
            _edit_splashMenu_revoke.enabled = YES;
        }
            break;
        default:
            break;
    }
}

/** 设置绘画拾色器默认颜色 */
- (void)setDrawSliderColorValue:(CGFloat)value
{
    self.draw_colorSlider.value = value;
}

#pragma mark - LFColorSliderDelegate
- (void)lf_colorSliderDidChangeColor:(UIColor *)color
{
    if ([self.delegate respondsToSelector:@selector(lf_editToolbar:drawColorDidChange:)]) {
        [self.delegate lf_editToolbar:self drawColorDidChange:color];
    }
}

@end
