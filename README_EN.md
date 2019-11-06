# LFImagePickerController

[中文](https://github.com/lincf0912/LFImagePickerController/blob/master/README.md)

* It starts with the TZImagePickerController project. 
Thanks for sharing.
* Compatible with custom photos/videos to display.
* Support for Gif (compressible), video (compressible), picture (compressible).
* Support for editing photos and videos. (it depends on the LFMediaEditingController library and has no editing by default.)
* Video editors need to access the music library and need to add NSAppleMusicUsageDescription to info.plist.
* Support interface orientation.
* Support for i18n configuration. (copy LFImagePickerController.bundle\ LFImagePickerController.strings to your project and modify the corresponding value. For more information, see DEMO; Note: it does not follow the system language switch display.)
* For more information on the properties, see LFImagePickerController.h.

## Installation

* CocoaPods：pod 'LFImagePickerController' or pod 'LFImagePickerController/LFMediaEdit' (with editing)

## Demo configuration editing（You don't have to edit. You can ignore it.）

* Install the LFMediaEditingController library using `pod install`
* Project for LFImagePickerController-- > Build Settings-- > Preprocessor Macros-- > add `LF_MEDIAEDIT=1` to Debug and Release

## Demonstration

* LFImagePickerController *imagePicker = [[LFImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
* //Set up according to demand
* imagePicker.allowTakePicture = NO;  //Do not display take photo button
* imagePicker.doneBtnTitleStr = @"Done"; //Modify the name of the done button
* [self presentViewController:imagePicker animated:YES completion:nil];

## Presentation

![image](https://github.com/lincf0912/LFImagePickerController/blob/master/ScreenShots/screenshot.gif)

## Presentation iOS13 UIModalPresentationPageSheet

![image](https://github.com/lincf0912/LFImagePickerController/blob/master/ScreenShots/screenshot_iOS13.gif)