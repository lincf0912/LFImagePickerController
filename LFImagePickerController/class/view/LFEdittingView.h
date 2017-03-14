//
//  LFEdittingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/10.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFScrollView.h"

@interface LFEdittingView : LFScrollView

@property (nonatomic, strong) UIImage *image;

/** 最小尺寸 CGSizeMake(80, 80) */
@property (nonatomic, assign) CGSize clippingMinSize;
/** 最大尺寸 self.bounds */
@property (nonatomic, assign) CGRect clippingMaxRect;

@property (nonatomic, assign) BOOL isClipping;
- (void)setIsClipping:(BOOL)isClipping animated:(BOOL)animated;

@end
