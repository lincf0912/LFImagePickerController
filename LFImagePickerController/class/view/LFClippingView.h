//
//  LFClippingView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/6.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFClippingView : UIView

@property (nonatomic, strong) UIImage *image;

/** 最小尺寸 CGSizeMake(80, 80) */
@property (nonatomic, assign) CGSize clippingMinSize;
/** 最大尺寸 CGRectInset(self.bounds, 30, 50) */
@property (nonatomic, assign) CGRect clippingMaxRect;

/** 还原 */
- (void)reset;
@end
