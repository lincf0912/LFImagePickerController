//
//  ViewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "ViewController.h"
#import "LFImagePickerController.h"

@interface ViewController () <LFImagePickerControllerDelegate>
{
    UITapGestureRecognizer *singleTapRecognizer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /** 单击的 Recognizer */
    singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singlePressed:)];
    /** 点击的次数 */
    singleTapRecognizer.numberOfTapsRequired = 1; // 单击
    /** 给view添加一个手势监测 */
    singleTapRecognizer.enabled = NO;
    [self.view addGestureRecognizer:singleTapRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    singleTapRecognizer.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    singleTapRecognizer.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)singlePressed:(UITapGestureRecognizer *)sender
{
    NSLog(@"启动图片选择器");
    LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePicker.allowTakePicture = NO;
    imagePicker.doneBtnTitleStr = @"发送";
    [self presentViewController:imagePicker animated:YES completion:nil];
}


@end
