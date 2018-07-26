//
//  LFAssetPhotoProtocol.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2018/7/17.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LFAssetPhotoProtocol <NSObject>

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) UIImage *originalImage;

@property (nonatomic, strong) UIImage *thumbnailImage;

@end
