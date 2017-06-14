//
//  UIView+LFAnimate.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OscillatoryAnimationType) {
    OscillatoryAnimationToBigger,
    OscillatoryAnimationToSmaller,
};

@interface UIView (LFAnimate)

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(OscillatoryAnimationType)type;
@end
