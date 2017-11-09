//
//  LFLayoutPickerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFLayoutPickerController.h"
#import "LFImagePickerHeader.h"
#import "LFBaseViewController.h"
#import "UIView+LFFrame.h"
#import "UIAlertView+LF_Block.h"

@interface LFLayoutPickerController () <UINavigationControllerDelegate>
{
    UIButton *_progressHUD;
    UIView *_HUDContainer;
    UIActivityIndicatorView *_HUDIndicatorView;
    UILabel *_HUDLabel;
    
    
    UIStatusBarStyle _originStatusBarStyle;
}
@end

@implementation LFLayoutPickerController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    [self configDefaultSetting];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor clearColor];
//    self.navigationBar.barStyle = UIBarStyleBlack;
//    self.navigationBar.translucent = YES;
    self.delegate = self;
    
    if (iOS7Later) {
//        self.automaticallyAdjustsScrollViewInsets = NO;
        
        UIImage *backIndicatorImage = bundleImageNamed(@"navigationbar_back_arrow");
        self.navigationBar.backIndicatorImage = backIndicatorImage;
        self.navigationBar.backIndicatorTransitionMaskImage = backIndicatorImage;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _HUDContainer.center = self.view.center;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)setNaviBgColor:(UIColor *)naviBgColor {
    _naviBgColor = naviBgColor;
    self.navigationBar.barTintColor = naviBgColor;
}

- (void)setNaviTitleColor:(UIColor *)naviTitleColor {
    _naviTitleColor = naviTitleColor;
    [self configNaviTitleAppearance];
}

- (void)setNaviTitleFont:(UIFont *)naviTitleFont {
    _naviTitleFont = naviTitleFont;
    [self configNaviTitleAppearance];
}

- (void)configNaviTitleAppearance {
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = self.naviTitleColor;
    textAttrs[NSFontAttributeName] = self.naviTitleFont;
    self.navigationBar.titleTextAttributes = textAttrs;
}

- (void)setBarItemTextFont:(UIFont *)barItemTextFont {
    _barItemTextFont = barItemTextFont;
    [self configBarButtonItemAppearance];
}

- (void)setBarItemTextColor:(UIColor *)barItemTextColor {
    _barItemTextColor = barItemTextColor;
    self.navigationBar.tintColor = self.barItemTextColor;
    [self configBarButtonItemAppearance];
}

- (void)configBarButtonItemAppearance {
    UIBarButtonItem *barItem;
    if (iOS9Later) {
        barItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[LFLayoutPickerController class]]];
    } else {
        barItem = [UIBarButtonItem appearanceWhenContainedIn:[LFLayoutPickerController class], nil];
    }
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = self.barItemTextColor;
    textAttrs[NSFontAttributeName] = self.barItemTextFont;
    [barItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
}

- (void)configDefaultSetting {
    
    self.oKButtonTitleColorNormal   = [UIColor colorWithRed:(26/255.0) green:(173/255.0) blue:(25/255.0) alpha:1.0];
    self.oKButtonTitleColorDisabled = [UIColor colorWithRed:(23/255.0) green:(82/255.0) blue:(22/255.0) alpha:1.0];
    self.naviBgColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:1.0];
    self.naviTitleColor = [UIColor whiteColor];
    self.naviTitleFont = [UIFont systemFontOfSize:17];
    self.barItemTextFont = [UIFont systemFontOfSize:15];
    self.barItemTextColor = [UIColor whiteColor];
    self.toolbarBgColor = [UIColor colorWithWhite:.1f alpha:0.9];
    self.toolbarTitleColorNormal = [UIColor whiteColor];
    self.toolbarTitleColorDisabled = [UIColor colorWithRed:(92/255.0) green:(102/255.0) blue:(106/255.0) alpha:1.0];
    self.toolbarTitleFont = [UIFont systemFontOfSize:14];
    self.previewNaviBgColor = [UIColor colorWithRed:(36/255.0) green:(36/255.0)  blue:(36/255.0) alpha:0.9];
    
    
    [self configDefaultImageName];
    [self configDefaultBtnTitle];
}

- (void)configDefaultImageName {
    self.takePictureImageName = @"takePicture.png";
    self.photoSelImageName = @"photo_sel_photoPickerVc.png";
    self.photoDefImageName = @"photo_def_photoPickerVc.png";
    self.photoNumberIconImageName = @"photo_number_icon.png";
    self.photoOriginDefImageName = @"photo_original_def.png";
    self.photoOriginSelImageName = @"photo_original_sel.png";
}

- (void)configDefaultBtnTitle {
    self.doneBtnTitleStr = @"完成";
    self.cancelBtnTitleStr = @"取消";
    self.previewBtnTitleStr = @"预览";
    self.editBtnTitleStr = @"编辑";
    self.fullImageBtnTitleStr = @"原图";
    self.settingBtnTitleStr = @"设置";
    self.processHintStr = @"正在处理...";
}

- (void)showAlertWithTitle:(NSString *)title {
    [self showAlertWithTitle:title complete:nil];
}

- (void)showAlertWithTitle:(NSString *)title complete:(void (^)(void))complete
{
    [self showAlertWithTitle:title message:nil complete:complete];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message complete:(void (^)(void))complete
{
    [self showAlertWithTitle:title cancelTitle:@"确定" message:message complete:complete];
}

- (void)showAlertWithTitle:(NSString *)title cancelTitle:(NSString *)cancelTitle message:(NSString *)message complete:(void (^)(void))complete
{
    if (iOS8Later) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (complete) {
                complete();
            }
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelTitle otherButtonTitles:nil block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (complete) {
                complete();
            }
        }] show];
    }
}

- (void)showProgressHUDText:(NSString *)text isTop:(BOOL)isTop
{
    [self hideProgressHUD];
    
    if (!_progressHUD) {
        _progressHUD = [UIButton buttonWithType:UIButtonTypeCustom];
        [_progressHUD setBackgroundColor:[UIColor clearColor]];
        _progressHUD.frame = [UIScreen mainScreen].bounds;
        
        _HUDContainer = [[UIView alloc] init];
        _HUDContainer.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width - 120) / 2, ([[UIScreen mainScreen] bounds].size.height - 90) / 2, 120, 90);
        _HUDContainer.layer.cornerRadius = 8;
        _HUDContainer.clipsToBounds = YES;
        _HUDContainer.backgroundColor = [UIColor darkGrayColor];
        _HUDContainer.alpha = 0.7;
        
        _HUDIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _HUDIndicatorView.frame = CGRectMake(45, 15, 30, 30);
        
        _HUDLabel = [[UILabel alloc] init];
        _HUDLabel.frame = CGRectMake(0,40, 120, 50);
        _HUDLabel.textAlignment = NSTextAlignmentCenter;
        _HUDLabel.font = [UIFont systemFontOfSize:15];
        _HUDLabel.textColor = [UIColor whiteColor];
        
        [_HUDContainer addSubview:_HUDLabel];
        [_HUDContainer addSubview:_HUDIndicatorView];
        [_progressHUD addSubview:_HUDContainer];
    }
    
    _HUDLabel.text = text ? text : self.processHintStr;
    
    [_HUDIndicatorView startAnimating];
    UIView *view = isTop ? [[UIApplication sharedApplication] keyWindow] : self.view;
    [view addSubview:_progressHUD];
}

- (void)showProgressHUDText:(NSString *)text
{
    [self showProgressHUDText:text isTop:NO];
}

- (void)showProgressHUD {
    
    [self showProgressHUDText:nil];
    
}

- (void)hideProgressHUD {
    if (_progressHUD) {
        [_HUDIndicatorView stopAnimating];
        [_progressHUD removeFromSuperview];
    }
}

#pragma mark - UINavigationController Delegate Methods
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([viewController isKindOfClass:[LFBaseViewController class]])
    {
        /** 处理推送VC传参 */
        LFBaseViewController *targetVC = (LFBaseViewController *)viewController;        
        [self setNavigationBarHidden:targetVC.isHiddenNavBar animated:animated];
    }
}

#pragma mark - 状态栏
- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
}
//- (UIStatusBarStyle)preferredStatusBarStyle

- (UIViewController *)childViewControllerForStatusBarHidden
{
    return self.topViewController;
}
//- (BOOL)prefersStatusBarHidden

@end
