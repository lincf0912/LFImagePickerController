//
//  LFBaseViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "LFImagePickerController.h"

@interface LFBaseViewController ()

@end

@implementation LFBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
}

- (CGFloat)navigationHeight
{
    CGFloat top = CGRectGetHeight(self.navigationController.navigationBar.frame);
    if (iOS7Later) top += 20;
    return top;
}

- (CGRect)viewFrameWithoutNavigation
{
    CGFloat top = [self navigationHeight];
    CGFloat height = self.view.height - top;
    
    return CGRectMake(0, top, self.view.width, height);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - 状态栏
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return self.isHiddenStatusBar;
}

@end
