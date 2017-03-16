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
#import "LFImagePickerType.h"

#import "LFEditToolbar.h"
#import "LFEdittingView.h"

#define kSplashMenu_Button_Tag1 95
#define kSplashMenu_Button_Tag2 96


@interface LFPhotoEdittingController () <LFEditToolbarDelegate>
{
    /** 编辑模式 */
    LFEdittingView *_edittingView;
    
    UIView *_edit_naviBar;
    LFEditToolbar *_edit_toolBar;
    
    /** 剪切菜单 */
    UIView *_edit_clipping_toolBar;
    
    /** 单击手势 */
    UITapGestureRecognizer *singleTapRecognizer;
}

/** 隐藏控件 */
@property (nonatomic, assign) BOOL isHideNaviBar;

/** 旧编辑对象 */
@property (nonatomic, strong) LFPhotoEdit *oldPhotoEdit;
@end

@implementation LFPhotoEdittingController

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

//    [self configPhotoEditManager];
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
    _edittingView = [[LFEdittingView alloc] initWithFrame:self.view.bounds];
    if (_editImage) {
        [self setEditImage:_editImage];
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
    _edit_toolBar = [[LFEditToolbar alloc] init];
    _edit_toolBar.delegate = self;
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

#pragma mark - LFEditToolbarDelegate 底部栏(action)

/** 一级菜单点击事件 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar mainDidSelectAtIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
        {
            
        }
            break;
        case 1:
            break;
        case 2:
            break;
        case 3:
        {
            
        }
            break;
        case 4:
        {
            [_edittingView setIsClipping:YES animated:YES];
            /** 切换菜单 */
            [self.view addSubview:self.edit_clipping_toolBar];
            [UIView animateWithDuration:0.25f animations:^{
                self.edit_clipping_toolBar.alpha = 1.f;
            }];
            singleTapRecognizer.enabled = NO;
            [self singlePressed];
        }
            break;
        default:
            break;
    }
}
/** 二级菜单点击事件-撤销 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidRevokeAtIndex:(NSUInteger)index
{
    
}
/** 二级菜单点击事件-按钮 */
- (void)lf_editToolbar:(LFEditToolbar *)editToolbar subDidSelectAtIndex:(NSIndexPath *)indexPath
{
    
}
/** 撤销允许权限获取 */
- (BOOL)lf_editToolbar:(LFEditToolbar *)editToolbar canRevokeAtIndex:(NSUInteger)index
{
    return YES;
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
        [leftButton setTitle:@"cancel" forState:UIControlStateNormal];
        [leftButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [leftButton addTarget:self action:@selector(clippingCancel:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:leftButton];
        
        /** 中 */
        UIButton *centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
        centerButton.frame = (CGRect){{(CGRectGetWidth(_edit_clipping_toolBar.frame)-size.width)/2,0}, size};
        [centerButton setTitle:@"还原" forState:UIControlStateNormal];
        [centerButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
        [centerButton addTarget:self action:@selector(clippingReset:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:centerButton];
        
        /** 右 */
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        rightButton.frame = (CGRect){{CGRectGetWidth(_edit_clipping_toolBar.frame)-size.width-10,0}, size};
        [rightButton setTitle:@"ok" forState:UIControlStateNormal];
        [rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [rightButton addTarget:self action:@selector(clippingOk:) forControlEvents:UIControlEventTouchUpInside];
        [_edit_clipping_toolBar addSubview:rightButton];
    }
    return _edit_clipping_toolBar;
}

- (void)clippingCancel:(UIButton *)button
{
    singleTapRecognizer.enabled = YES;
    [_edittingView setIsClipping:NO animated:YES];
    [UIView animateWithDuration:.25f animations:^{
        self.edit_clipping_toolBar.alpha = 0.f;
    } completion:^(BOOL finished) {
        [self.edit_clipping_toolBar removeFromSuperview];
    }];

    [self singlePressed];
}

- (void)clippingReset:(UIButton *)button
{
    [_edittingView reset];
}

- (void)clippingOk:(UIButton *)button
{
    [self clippingCancel:button];
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
    if (_photoEdit.drawCanUndo) [_edit_toolBar setRevokeAtIndex:LFPhotoEdittingType_draw];
    
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
    if (_photoEdit.splashCanUndo) [_edit_toolBar setRevokeAtIndex:LFPhotoEdittingType_splash];
    
    _isHideNaviBar = NO;
    [self changedBarState];
}
/** 创建马赛克图片 */
- (UIImage *)lf_photoEditSplashImage:(LFPhotoEdit *)editer
{
    /** 压缩图片 */
    return [self.editImage fastestCompressImageWithSize:200];
}

#pragma mark - LFPhotoEditClippingDelegate
/** 提供需要剪切的图片 */
- (UIImage *)lf_photoEditClippingImage:(LFPhotoEdit *)editer
{
    return self.editImage;
}

- (void)changedBarState
{
    [UIView animateWithDuration:.25f animations:^{
        CGFloat alpha = _isHideNaviBar ? 0.f : 1.f;
        _edit_naviBar.alpha = alpha;
        _edit_toolBar.alpha = alpha;
    }];
}
@end
