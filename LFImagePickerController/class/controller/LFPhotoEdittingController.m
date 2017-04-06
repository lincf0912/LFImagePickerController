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
#import "UIView+LFCommon.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_ImageCompress.h"
#import "LFImagePickerType.h"

#import "LFEdittingView.h"
#import "LFEditToolbar.h"
#import "LFStickerBar.h"
#import "LFTextBar.h"

#define kSplashMenu_Button_Tag1 95
#define kSplashMenu_Button_Tag2 96



@interface LFPhotoEdittingController () <LFEditToolbarDelegate, LFStickerBarDelegate, LFTextBarDelegate, LFPhotoEditDelegate, LFEdittingViewDelegate>
{
    /** 编辑模式 */
    LFEdittingView *_edittingView;
    
    UIView *_edit_naviBar;
    /** 底部栏菜单 */
    LFEditToolbar *_edit_toolBar;
    /** 剪切菜单 */
    UIView *_edit_clipping_toolBar;
    
    /** 贴图菜单 */
    LFStickerBar *_edit_sticker_toolBar;
    
    /** 单击手势 */
    UITapGestureRecognizer *singleTapRecognizer;
}

/** 隐藏控件 */
@property (nonatomic, assign) BOOL isHideNaviBar;

/** 剪切菜单——还原按钮 */
@property (nonatomic, weak) UIButton *edit_clipping_toolBar_reset;

@end

@implementation LFPhotoEdittingController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isHiddenNavBar = YES;
        self.isHiddenStatusBar = YES;
    }
    return self;
}

- (void)setEditImage:(UIImage *)editImage
{
    _editImage = editImage;
    _edittingView.image = editImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configScrollView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
}

- (void)dealloc{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建视图
- (void)configScrollView
{
    _edittingView = [[LFEdittingView alloc] initWithFrame:self.view.bounds];
    _edittingView.editDelegate = self;
    _edittingView.clippingDelegate = self;
    _edittingView.image = _editImage;
    if (_photoEdit) {
        [self setEditImage:_photoEdit.editImage];
        _edittingView.photoEditData = _photoEdit.editData;
    }
    
    /** 单击的 Recognizer */
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    /** 给view添加一个手势监测 */
    [self.view addGestureRecognizer:singleTapRecognizer];
    
    [self.view addSubview:_edittingView];
}

- (void)configCustomNaviBar
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat margin = 10, topbarHeight = 64;
    CGFloat size = topbarHeight - margin*2;
    
    _edit_naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, topbarHeight)];
    _edit_naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    UIButton *_edit_cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, margin, size, size)];
    [_edit_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    _edit_cancelButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [_edit_cancelButton setTitleColor:[UIColor colorWithWhite:0.8f alpha:1.f] forState:UIControlStateNormal];
    [_edit_cancelButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *_edit_finishButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - (size + margin), margin, size, size)];
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
    _edit_toolBar = [[LFEditToolbar alloc] init];
    _edit_toolBar.delegate = self;
    [_edit_toolBar setDrawSliderColorValue:0.3612]; /** 红色 */
    /** 绘画颜色一致 */
    [_edittingView setDrawColor:[UIColor redColor]];
    [self.view addSubview:_edit_toolBar];
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
        [self.delegate lf_PhotoEdittingController:self didCancelPhotoEdit:self.photoEdit];
    }
}

- (void)finishButtonClick
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    /** 取消贴图激活 */
    [_edittingView stickerDeactivated];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /** 处理编辑图片 */
        UIImage *image = [_edittingView captureImage];
        NSDictionary *data = [_edittingView photoEditData];
        LFPhotoEdit *photoEdit = (data ? [[LFPhotoEdit alloc] initWithEditImage:self.editImage previewImage:image data:data] : nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(lf_PhotoEdittingController:didFinishPhotoEdit:)]) {
                [self.delegate lf_PhotoEdittingController:self didFinishPhotoEdit:photoEdit];
            }
            [imagePickerVc hideProgressHUD];
        });
    });
}

#pragma mark - LFEditToolbarDelegate 底部栏(action)

/** 一级菜单点击事件 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar mainDidSelectAtIndex:(NSUInteger)index
{
    /** 取消贴图激活 */
    [_edittingView stickerDeactivated];
    
    switch (index) {
        case 0:
        {
            /** 关闭涂抹 */
            _edittingView.splashEnable = NO;
            /** 打开绘画 */
            _edittingView.drawEnable = !_edittingView.drawEnable;
        }
            break;
        case 1:
        {
            [self singlePressed];
            [self changeStickerMenu:YES];
        }
            break;
        case 2:
        {
            [self showTextBarController:nil];
        }
            break;
        case 3:
        {
            /** 关闭绘画 */
            _edittingView.drawEnable = NO;
            /** 打开涂抹 */
            _edittingView.splashEnable = !_edittingView.splashEnable;
        }
            break;
        case 4:
        {
            [_edittingView setIsClipping:YES animated:YES];
            [self changeClipMenu:YES];
            self.edit_clipping_toolBar_reset.enabled = _edittingView.canReset;
        }
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-撤销 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidRevokeAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
        {
            [_edittingView drawUndo];
        }
            break;
        case 1:
            break;
        case 2:
            break;
        case 3:
        {
            [_edittingView splashUndo];
        }
            break;
        case 4:
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-按钮 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidSelectAtIndex:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
            break;
        case 2:
            break;
        case 3:
        {
            _edittingView.splashState = indexPath.row == 1;
        }
            break;
        case 4:
            break;
        default:
            break;
    }
}
/** 撤销允许权限获取 */
- (BOOL)lf_editToolbar:(LFEditToolbar *)editToolbar canRevokeAtIndex:(NSUInteger)index
{
    BOOL canUndo = NO;
    switch (index) {
        case 0:
        {
            canUndo = [_edittingView drawCanUndo];
        }
            break;
        case 1:
            break;
        case 2:
            break;
        case 3:
        {
            canUndo = [_edittingView splashCanUndo];
        }
            break;
        case 4:
            break;
        default:
            break;
    }
    
    return canUndo;
}
/** 二级菜单滑动事件-绘画 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar drawColorDidChange:(UIColor *)color
{
    [_edittingView setDrawColor:color];
}

#pragma mark - 剪切底部栏（懒加载）
- (UIView *)edit_clipping_toolBar
{
    if (_edit_clipping_toolBar == nil) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        
        _edit_clipping_toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
        CGFloat rgb = 34 / 255.0;
        _edit_clipping_toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
        _edit_clipping_toolBar.alpha = 0.f;
        
        CGSize size = CGSizeMake(44, _edit_clipping_toolBar.frame.size.height);
        /** 左 */
        UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = (CGRect){{10,0}, size};
        [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn.png") forState:UIControlStateNormal];
        [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn_HL.png") forState:UIControlStateHighlighted];
        [leftButton setImage:bundleEditImageNamed(@"EditImageCancelBtn_HL.png") forState:UIControlStateSelected];
        [leftButton addTarget:self action:@selector(clippingCancel:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:leftButton];
        
        /** 中 */
        UIButton *centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        centerButton.frame = (CGRect){{(CGRectGetWidth(_edit_clipping_toolBar.frame)-size.width)/2,0}, size};
        [centerButton setTitle:@"还原" forState:UIControlStateNormal];
        [centerButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
        [centerButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [centerButton addTarget:self action:@selector(clippingReset:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:centerButton];
        self.edit_clipping_toolBar_reset = centerButton;
        
        /** 右 */
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = (CGRect){{CGRectGetWidth(_edit_clipping_toolBar.frame)-size.width-10,0}, size};
        [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn.png") forState:UIControlStateNormal];
        [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateHighlighted];
        [rightButton setImage:bundleEditImageNamed(@"EditImageConfirmBtn_HL.png") forState:UIControlStateSelected];
        [rightButton addTarget:self action:@selector(clippingOk:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:rightButton];
    }
    return _edit_clipping_toolBar;
}

- (void)clippingCancel:(UIButton *)button
{
    [_edittingView cancelClipping:YES];
    [self changeClipMenu:NO];
}

- (void)clippingReset:(UIButton *)button
{
    [_edittingView reset];
    self.edit_clipping_toolBar_reset.enabled = _edittingView.canReset;
}

- (void)clippingOk:(UIButton *)button
{
    [_edittingView setIsClipping:NO animated:YES];
    [self changeClipMenu:NO];
}

#pragma mark - 贴图菜单（懒加载）
- (LFStickerBar *)edit_sticker_toolBar
{
    if (_edit_sticker_toolBar == nil) {
        CGFloat w=self.view.width, h=175.f;
        _edit_sticker_toolBar = [[LFStickerBar alloc] initWithFrame:CGRectMake(0, self.view.height, w, h)];
        _edit_sticker_toolBar.delegate = self;
    }
    return _edit_sticker_toolBar;
}

#pragma mark - LFStickerBarDelegate
- (void)lf_stickerBar:(LFStickerBar *)lf_stickerBar didSelectImage:(UIImage *)image
{
    if (image) {
        [_edittingView createStickerImage:image];
    }
    [self singlePressed];
}

#pragma mark - LFTextBarDelegate
/** 完成回调 */
- (void)lf_textBarController:(LFTextBar *)textBar didFinishText:(LFText *)text
{
    if (text) {
        /** 判断是否更改文字 */
        if (textBar.showText) {
            [_edittingView changeSelectStickerText:text];
        } else {
            [_edittingView createStickerText:text];
        }
    } else {
        if (textBar.showText) { /** 文本被清除，删除贴图 */
            [_edittingView removeSelectStickerView];
        }
    }
    [self lf_textBarControllerDidCancel:textBar];
}
/** 取消回调 */
- (void)lf_textBarControllerDidCancel:(LFTextBar *)textBar
{
    /** 显示顶部栏 */
    _isHideNaviBar = NO;
    [self changedBarState];
    /** 更改文字情况才重新激活贴图 */
    if (textBar.showText) {
        [_edittingView activeSelectStickerView];
    }
    [textBar resignFirstResponder];
    
    [UIView animateWithDuration:0.25f delay:0.f options:UIViewAnimationOptionCurveLinear animations:^{
        textBar.y = self.view.height;
    } completion:^(BOOL finished) {
        [textBar removeFromSuperview];
    }];
}

#pragma mark - LFPhotoEditDelegate
#pragma mark - LFPhotoEditDrawDelegate
/** 开始绘画 */
- (void)lf_photoEditDrawBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束绘画 */
- (void)lf_photoEditDrawEnded
{
    /** 撤销生效 */
    if (_edittingView.drawCanUndo) [_edit_toolBar setRevokeAtIndex:LFPhotoEdittingType_draw];
    
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFPhotoEditStickerDelegate
/** 点击贴图 isActive=YES 选中的情况下点击 */
- (void)lf_photoEditStickerDidSelectViewIsActive:(BOOL)isActive
{
    _isHideNaviBar = NO;
    [self changedBarState];
    if (isActive) { /** 选中的情况下点击 */
        LFText *text = [_edittingView getSelectStickerText];
        if (text) {
            [self showTextBarController:text];
        }
    }
}

#pragma mark - LFPhotoEditSplashDelegate
/** 开始模糊 */
- (void)lf_photoEditSplashBegan
{
    _isHideNaviBar = YES;
    [self changedBarState];
}
/** 结束模糊 */
- (void)lf_photoEditSplashEnded
{
    /** 撤销生效 */
    if (_edittingView.splashCanUndo) [_edit_toolBar setRevokeAtIndex:LFPhotoEdittingType_splash];
    
    _isHideNaviBar = NO;
    [self changedBarState];
}

#pragma mark - LFEdittingViewDelegate
/** 剪裁发生变化后 */
- (void)lf_edittingViewDidEndZooming:(LFEdittingView *)edittingView
{
    self.edit_clipping_toolBar_reset.enabled = edittingView.canReset;
}
/** 剪裁目标移动后 */
- (void)lf_edittingViewEndDecelerating:(LFEdittingView *)edittingView
{
    self.edit_clipping_toolBar_reset.enabled = edittingView.canReset;
}

#pragma mark - private
- (void)changedBarState
{
    /** 隐藏贴图菜单 */
    [self changeStickerMenu:NO];
    
    [UIView animateWithDuration:.25f animations:^{
        CGFloat alpha = _isHideNaviBar ? 0.f : 1.f;
        _edit_naviBar.alpha = alpha;
        _edit_toolBar.alpha = alpha;
    }];
}

- (void)changeClipMenu:(BOOL)isChanged
{
    if (isChanged) {
        /** 关闭所有编辑 */
        [_edittingView photoEditEnable:NO];
        /** 切换菜单 */
        [self.view addSubview:self.edit_clipping_toolBar];
        [UIView animateWithDuration:0.25f animations:^{
            self.edit_clipping_toolBar.alpha = 1.f;
        }];
        singleTapRecognizer.enabled = NO;
        [self singlePressed];
    } else {
        if (_edit_clipping_toolBar.superview == nil) return;

        /** 开启编辑 */
        [_edittingView photoEditEnable:YES];
        
        singleTapRecognizer.enabled = YES;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_clipping_toolBar.alpha = 0.f;
        } completion:^(BOOL finished) {
            [self.edit_clipping_toolBar removeFromSuperview];
        }];
        
        [self singlePressed];
    }
}

- (void)changeStickerMenu:(BOOL)isChanged
{
    if (isChanged) {
        [self.view addSubview:self.edit_sticker_toolBar];
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height-frame.size.height;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_sticker_toolBar.frame = frame;
        }];
    } else {
        if (_edit_sticker_toolBar.superview == nil) return;
        
        CGRect frame = self.edit_sticker_toolBar.frame;
        frame.origin.y = self.view.height;
        [UIView animateWithDuration:.25f animations:^{
            self.edit_sticker_toolBar.frame = frame;
        } completion:^(BOOL finished) {
            [_edit_sticker_toolBar removeFromSuperview];
            _edit_sticker_toolBar = nil;
        }];
    }
}

- (void)showTextBarController:(LFText *)text
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    LFTextBar *textBar = [[LFTextBar alloc] initWithFrame:CGRectMake(0, self.view.height, self.view.width, self.view.height)];
    textBar.showText = text;
    textBar.oKButtonTitleColorNormal = imagePickerVc.oKButtonTitleColorNormal;
    textBar.delegate = self;

    [self.view addSubview:textBar];
    
    [textBar becomeFirstResponder];
    [UIView animateWithDuration:0.25f animations:^{
        textBar.y = 0;
    } completion:^(BOOL finished) {
        /** 隐藏顶部栏 */
        _isHideNaviBar = YES;
        [self changedBarState];
    }];
}

@end
