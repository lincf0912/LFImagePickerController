//
//  LFPhotoEdittingController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEdittingController.h"
#import "LFImagePickerHeader.h"
#import "LFImagePickerController.h"
#import "UIView+LFFrame.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_ImageCompress.h"

#pragma mark - 自定义ScrollView

@interface LFScrollView : UIScrollView

@end

@implementation LFScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delaysContentTouches = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delaysContentTouches = NO;
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    if ([[LFPhotoEdit touchClass] containsObject:[view class]]) {
        if (event.allTouches.count == 1) { /** 1个手指 */
            return YES;
        } else if (event.allTouches.count == 2) { /** 2个手指 */
            return NO;
        }
    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    if ([[LFPhotoEdit touchClass] containsObject:[view class]]) {
        return NO;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end

#define kSplashMenu_Button_Tag1 95
#define kSplashMenu_Button_Tag2 96


@interface LFPhotoEdittingController () <UIScrollViewDelegate, LFPhotoEditDrawDelegate, LFPhotoEditStickerDelegate, LFPhotoEditSplashDelegate>
{
    /** 编辑模式 */
    LFScrollView *_scrollView;
    UIView *_containsView;
    UIImageView *_imageView;
    
    UIView *_edit_naviBar;
    UIView *_edit_toolBar;
    UIView *_edit_menuView;
    
    UIView *_edit_drawMenu;
    UIButton *_edit_drawMenu_revoke;
    UIView *_edit_splashMenu;
    UIButton *_edit_splashMenu_revoke;
    
    /** 当前激活菜单按钮 */
    UIButton *_edit_drawMenu_action_button;
    UIButton *_edit_splashMenu_action_button;
}

/** 隐藏控件 */
@property (nonatomic, assign) BOOL isHideNaviBar;

/** 当前点击按钮 */
@property (nonatomic, weak) UIButton *selectButton;

/** 旧编辑对象 */
@property (nonatomic, strong) LFPhotoEdit *oldPhotoEdit;
@end

@implementation LFPhotoEdittingController

- (void)setEditImage:(UIImage *)editImage
{
    _editImage = editImage;
    if (_imageView) {
        [_imageView setImage:_editImage];
        [_scrollView setZoomScale:1.f animated:NO];
        UIImage *image = _imageView.image;
        CGSize imageSize = [UIImage scaleImageSizeBySize:image.size targetSize:_containsView.size isBoth:NO];
        _containsView.size = imageSize;
        [self refreshImageZoomViewCenter];
        _imageView.frame = _containsView.bounds;
    }
}

- (void)setPhotoEdit:(LFPhotoEdit *)photoEdit
{
    if (_photoEdit != photoEdit) {
        _oldPhotoEdit = nil;
        /** 移除旧 */
        [_photoEdit clearContainer];
        _photoEdit = photoEdit;
        /** 保存一份作为旧编辑 */
        _oldPhotoEdit = [_photoEdit copy];
    }
    
    /** 设置新 */
    [_photoEdit setContainer:_containsView];
    _photoEdit.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configScrollView];
    [self configCustomNaviBar];
    [self configBottomToolBar];

    [self configPhotoEditManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)dealloc{
    [self.photoEdit clearContainer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建视图
- (void)configScrollView
{
    _scrollView = [[LFScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height)];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.delegate = self;
    _scrollView.scrollsToTop = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.contentOffset = CGPointMake(0, 0);
    /** 缩放 */
    _scrollView.bouncesZoom = YES;
    _scrollView.maximumZoomScale = 2.5;
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.multipleTouchEnabled = YES;
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _containsView = [[UIView alloc] initWithFrame:_scrollView.bounds];
    _containsView.contentMode = UIViewContentModeScaleAspectFit;
    
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    if (_editImage) {
        [self setEditImage:_editImage];
    }
    
    /** 单击的 Recognizer */
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    /** 给view添加一个手势监测 */
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    [_containsView addSubview:_imageView];
    [_scrollView addSubview:_containsView];
    
    [self.view addSubview:_scrollView];
}

- (void)configCustomNaviBar
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    _edit_naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 64)];
    _edit_naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    UIButton *_edit_cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 44, 44)];
    [_edit_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    _edit_cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_edit_cancelButton setTitleColor:[UIColor colorWithWhite:0.8f alpha:1.f] forState:UIControlStateNormal];
    [_edit_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - 54, 10, 44, 44)];
    [_edit_finishButton setTitle:@"完成" forState:UIControlStateNormal];
    _edit_finishButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_edit_finishButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_edit_finishButton addTarget:self action:@selector(finishButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_edit_naviBar addSubview:_edit_finishButton];
    [_edit_naviBar addSubview:_edit_cancelButton];
    
    [self.view addSubview:_edit_naviBar];
}

- (void)configBottomToolBar
{
    _edit_toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
    static CGFloat rgb = 34 / 255.0;
    _edit_toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    NSInteger buttonCount = 5;
    
    CGFloat width = CGRectGetWidth(_edit_toolBar.frame)/buttonCount;
    
    for (NSInteger i=0; i<buttonCount; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.frame = CGRectMake(width*i, 0, width, 44);
        button.titleLabel.font = [UIFont systemFontOfSize:14];
        //            [button setImage:<#(nullable UIImage *)#> forState:UIControlStateNormal];
        [button setTitle:[NSString stringWithFormat:@"%zd", i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(edit_toolBar_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_toolBar addSubview:button];
    }
    
    UIView *divide = [[UIView alloc] init];
    CGFloat rgb2 = 40 / 255.0;
    divide.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];
    divide.frame = CGRectMake(0, 0, self.view.width, 1);
    
    [_edit_toolBar addSubview:divide];
    
    [self.view addSubview:_edit_toolBar];
}

- (void)configPhotoEditManager
{
    if (_photoEdit == nil) {
        self.photoEdit = [[LFPhotoEdit alloc] init];
    } else {
        self.photoEdit = _photoEdit;
    }
}

#pragma mark - 顶部栏(action)
- (void)singlePressed
{
    _isHideNaviBar = !_isHideNaviBar;
    [self changedBarState];
}
- (void)cancelButtonClick
{
    if ([self.delegate respondsToSelector:@selector(lf_PhotoEdittingController:didCancelPhotoEdit:)]) {
        [self.delegate lf_PhotoEdittingController:self didCancelPhotoEdit:self.oldPhotoEdit];
    }
}

- (void)finishButtonClick
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.photoEdit mergedContainerLayer];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(lf_PhotoEdittingController:didFinishPhotoEdit:)]) {
                [self.delegate lf_PhotoEdittingController:self didFinishPhotoEdit:self.photoEdit];
            }
            [imagePickerVc hideProgressHUD];
        });
    });
}

#pragma mark - 底部栏(action)
- (void)edit_toolBar_buttonClick:(UIButton *)button
{
    if (self.editImage == nil) return;
    
    switch (button.tag) {
        case LFPhotoEdittingType_draw:
        {
            /** 关闭模糊 */
            self.photoEdit.splashEnable = NO;
            if ([self changedButton:button]) {
                /** 显示菜单 */
                [self showMenuView:[self drawMenu]];
                /** 开启绘画 */
                self.photoEdit.drawEnable = YES;
            } else {
                /** 关闭菜单 */
                [self hidenMenuView];
                /** 关闭绘画 */
                self.photoEdit.drawEnable = NO;
            }
        }
            break;
        case LFPhotoEdittingType_sticker:
        {
            UIImage *image = bundleStickerImageNamed(@"001.png");
            [self.photoEdit createStickerImage:image];
        }
            break;
        case LFPhotoEdittingType_text:
        {
            [self.photoEdit createStickerText:@"挖泥机"];
        }
            break;
        case LFPhotoEdittingType_splash:
        {
            /** 模糊模式需要停止绘画状态 */
            self.photoEdit.drawEnable = NO;
            if ([self changedButton:button]) {
                /** 显示菜单 */
                [self showMenuView:[self splashMenu]];
                /** 开启模糊 */
                self.photoEdit.splashEnable = YES;
                
            } else {
                /** 关闭菜单 */
                [self hidenMenuView];
                /** 关闭模糊 */
                self.photoEdit.splashEnable = NO;
            }
        }
            break;
        case LFPhotoEdittingType_crop:
            break;
    }
}

- (BOOL)changedButton:(UIButton *)button
{
    /** 选中按钮 */
    _selectButton.selected = !_selectButton.selected;
    if (_selectButton != button) {
        _selectButton = button;
        _selectButton.selected = !_selectButton.selected;
    } else {
        _selectButton = nil;
    }
    return _selectButton;
}

#pragma mark - 菜单栏
- (void)showMenuView:(UIView *)menu
{
    /** 将显示的菜单先关闭 */
    if (_edit_menuView) {
        [self hidenMenuView];
    }
    /** 显示新菜单 */
    _edit_menuView = menu;
    [self.view addSubview:_edit_menuView];
}
- (void)hidenMenuView
{
    [_edit_menuView removeFromSuperview];
    _edit_menuView = nil;
}

#pragma mark - 菜单栏(懒加载)
- (UIView *)drawMenu
{
    if (_edit_drawMenu == nil) {
        _edit_drawMenu = [[UIView alloc] initWithFrame:CGRectMake(_edit_toolBar.x, _edit_toolBar.y-55, _edit_toolBar.width, 55)];
        _edit_drawMenu.backgroundColor = _edit_toolBar.backgroundColor;
        
        /** 添加按钮获取点击 */
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = _edit_drawMenu.bounds;
        [_edit_drawMenu addSubview:button];
        
        _edit_drawMenu_revoke = [self revokeButtonWithType:LFPhotoEdittingType_draw];
        [_edit_drawMenu addSubview:_edit_drawMenu_revoke];
        
        _edit_drawMenu_revoke.enabled = _photoEdit.drawCanUndo;
    }
    return _edit_drawMenu;
}

- (UIView *)splashMenu
{
    if (_edit_splashMenu == nil) {
        _edit_splashMenu = [[UIView alloc] initWithFrame:CGRectMake(_edit_toolBar.x, _edit_toolBar.y-55, _edit_toolBar.width, 55)];
        _edit_splashMenu.backgroundColor = _edit_toolBar.backgroundColor;
        
        /** 添加按钮获取点击 */
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.frame = _edit_splashMenu.bounds;
        [_edit_splashMenu addSubview:button];
        
        _edit_splashMenu_revoke = [self revokeButtonWithType:LFPhotoEdittingType_splash];
        [_edit_splashMenu addSubview:_edit_splashMenu_revoke];
        
        /** 剩余长度 */
        CGFloat width = CGRectGetMinX(_edit_splashMenu_revoke.frame);
        /** 按钮个数 */
        int count = 2;
        /** 平分空间 */
        CGFloat averageWidth = width/(count+1);
        
        UIButton *action1 = [UIButton buttonWithType:UIButtonTypeCustom];
        action1.frame = CGRectMake(averageWidth*1-44/2, (CGRectGetHeight(_edit_splashMenu.frame)-30)/2, 44, 30);
        [action1 addTarget:self action:@selector(splashMenu_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        action1.backgroundColor = [UIColor redColor];
        action1.tag = kSplashMenu_Button_Tag1;
        [_edit_splashMenu addSubview:action1];
        /** 优先激活首个按钮 */
        action1.selected = YES;
        _edit_splashMenu_action_button = action1;
        
        UIButton *action2 = [UIButton buttonWithType:UIButtonTypeCustom];
        action2.frame = CGRectMake(averageWidth*2-44/2, (CGRectGetHeight(_edit_splashMenu.frame)-30)/2, 44, 30);
        [action2 addTarget:self action:@selector(splashMenu_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        action2.backgroundColor = [UIColor redColor];
        action2.tag = kSplashMenu_Button_Tag2;
        [_edit_splashMenu addSubview:action2];
        
    }
    _edit_splashMenu_revoke.enabled = _photoEdit.splashCanUndo;
    return _edit_splashMenu;
}

- (UIButton *)revokeButtonWithType:(LFPhotoEdittingType)type
{
    UIButton *revoke = [UIButton buttonWithType:UIButtonTypeCustom];
    revoke.frame = CGRectMake(_edit_toolBar.width-44-5, 0, 44, 55);
    [revoke setTitle:@"撤销" forState:UIControlStateNormal];
    revoke.titleLabel.font = [UIFont systemFontOfSize:14.f];
    revoke.tag = type;
    [revoke addTarget:self action:@selector(revoke_buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    return revoke;
}

#pragma mark - 菜单栏(action)
- (void)revoke_buttonClick:(UIButton *)button
{
    if (button.tag == LFPhotoEdittingType_draw) {
        [_photoEdit drawUndo];
        /** 撤销失效 */
        _edit_drawMenu_revoke.enabled = _photoEdit.drawCanUndo;
    } else if (button.tag == LFPhotoEdittingType_splash) {
        [_photoEdit splashUndo];
        _edit_splashMenu_revoke.enabled = _photoEdit.splashCanUndo;
    }
}

- (void)splashMenu_buttonClick:(UIButton *)button
{
    if (_edit_splashMenu_action_button != button) {
        _edit_splashMenu_action_button.selected = NO;
        button.selected = YES;
        _edit_splashMenu_action_button = button;
        if (button.tag == kSplashMenu_Button_Tag1) {
            self.photoEdit.splashState = NO;
        } else if (button.tag == kSplashMenu_Button_Tag2) {
            self.photoEdit.splashState = YES;
        }
    }
}


#pragma mark - UIScrollViewDelegate
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _containsView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshImageZoomViewCenter];
}


#pragma mark - LFPhotoEditDrawDelegate
/** 开始绘画 */
- (void)lf_photoEditDrawBegan:(LFPhotoEdit *)editer
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束绘画 */
- (void)lf_photoEditDrawEnded:(LFPhotoEdit *)editer
{
    /** 撤销生效 */
    _edit_drawMenu_revoke.enabled = _photoEdit.drawCanUndo;
    
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFPhotoEditStickerDelegate
- (void)lf_photoEditsticker:(LFPhotoEdit *)editer didSelectView:(UIView *)view
{
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFPhotoEditSplashDelegate
/** 开始模糊 */
- (void)lf_photoEditSplashBegan:(LFPhotoEdit *)editer
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束模糊 */
- (void)lf_photoEditSplashEnded:(LFPhotoEdit *)editer
{
    /** 撤销生效 */
    _edit_splashMenu_revoke.enabled = _photoEdit.splashCanUndo;
    
    _isHideNaviBar = NO;
    [self changedBarState];
}
/** 创建马赛克图片 */
- (UIImage *)lf_photoEditSplashImage:(LFPhotoEdit *)editer
{
    /** 压缩图片 */
    return [self.editImage fastestCompressImageWithSize:200];
}

#pragma mark - Private
- (void)refreshImageZoomViewCenter {
    CGFloat offsetX = (_scrollView.width > _scrollView.contentSize.width) ? ((_scrollView.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.height > _scrollView.contentSize.height) ? ((_scrollView.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    _containsView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}

- (void)changedBarState
{
    [UIView animateWithDuration:.25f animations:^{
        CGFloat alpha = _isHideNaviBar ? 0.f : 1.f;
        _edit_naviBar.alpha = alpha;
        _edit_toolBar.alpha = alpha;
        _edit_menuView.alpha = alpha;
    }];
}
@end
