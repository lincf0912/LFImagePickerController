//
//  LFBaseViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/22.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFBaseViewController.h"
#import "LFImagePickerHeader.h"
#import "LFImagePickerController.h"

@interface LFBaseViewController ()

@end

@implementation LFBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
//    
//    if (imagePickerVc.viewControllers.count > 1) {
//        
//        UIViewController *prevVC = imagePickerVc.viewControllers[imagePickerVc.viewControllers.count-2];
//        if (imagePickerVc.viewControllers.count == 2) {
//            prevVC = nil;
//        }
//        
//        UIImage *leftBackImg = bundleImageNamed(@"navigationbar_back_arrow");
//        NSString *title = prevVC.navigationItem.title.length ? prevVC.navigationItem.title : @"返回";
//        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:self action:@selector(popToViewController)];
////        leftItem.tintColor = imagePickerVc.barItemTextColor;
//        [leftItem setBackgroundImage:[leftBackImg resizableImageWithCapInsets:UIEdgeInsetsMake(-1, leftBackImg.size.width, 0, 0)]  forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        
//        //[leftItem setBackButtonTitlePositionAdjustment:UIOffsetMake(-400.f, 0) forBarMetrics:UIBarMetricsDefault];
//        [leftItem setTitlePositionAdjustment:UIOffsetMake(5, 0) forBarMetrics:UIBarMetricsDefault];
//        [leftItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:16], NSFontAttributeName, nil] forState:UIControlStateNormal];
//        
//        //创建UIBarButtonSystemItemFixedSpace
//        UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//        
//        /* 在iPhone6之后（leftBarButtonItem才会向右偏移） */
//        spaceItem.width = ([[UIScreen mainScreen] currentMode].size.width > 640 ? -8 : 0);
//        
//        self.navigationItem.leftBarButtonItems = @[spaceItem, leftItem];
//    }
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
    CGFloat top = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    return top;
}

- (CGRect)viewFrameWithoutNavigation
{
    CGFloat top = [self navigationHeight];
    CGFloat height = self.view.frame.size.height - top;
    
    return CGRectMake(0, top, self.view.frame.size.width, height);
}

- (void)popToViewController
{
    [self.navigationController popViewControllerAnimated:YES];
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
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return self.isHiddenStatusBar;
}

@end
