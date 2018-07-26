//
//  LFAssetVideoProtocol.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2018/7/18.
//  Copyright © 2018年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LFAssetVideoProtocol <NSObject>

@property (nonatomic, copy) NSString *name;

@property (nonatomic, strong) NSURL *videoUrl;

@property (nonatomic, strong) UIImage *thumbnailImage;

@end
