//
//  LFZoomingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/16.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFEdittingProtocol.h"

@interface LFZoomingView : UIView <LFEdittingProtocol>

@property (nonatomic, strong) UIImage *image;

@end

