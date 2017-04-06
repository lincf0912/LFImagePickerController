# LFImagePickerController

* 拿了TZImagePickerController的项目来起步，节省了不少UI调整方面的时间，项目结构调整更加清晰，UI风格更加类似微信，加入图片编辑功能。
* 兼容非系统相册的调用方式
* 详细使用见LFImagePickerController.h 的初始化方法

## Installation 安装

* CocoaPods：pod 'LFImagePickerController'
* 手动导入：将LFImagePickerController\class文件夹拽入项目中，导入头文件：#import "LFImagePickerController.h"

## 调用代码

* LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
* //根据需求设置
* imagePicker.allowTakePicture = NO;  //不显示拍照按钮
* imagePicker.doneBtnTitleStr = @"发送"; //最终确定按钮名称
* [self presentViewController:imagePicker animated:YES completion:nil];

* 设置代理方法，按钮实现
* imagePicker.delegate;

## 图片展示

![image](https://github.com/lincf0912/LFImagePickerController/blob/master/ScreenShots/screenshot.gif)
