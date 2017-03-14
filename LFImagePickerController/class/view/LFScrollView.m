//
//  LFScrollView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFScrollView.h"

@implementation LFScrollView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delaysContentTouches = NO;
        self.canCancelContentTouches = NO;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delaysContentTouches = NO;
        self.canCancelContentTouches = NO;
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    //    if ([[LFPhotoEdit touchClass] containsObject:[view class]]) {
    //        if (event.allTouches.count == 1) { /** 1个手指 */
    //            return YES;
    //        } else if (event.allTouches.count == 2) { /** 2个手指 */
    //            return NO;
    //        }
    //    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    //    if ([[LFPhotoEdit touchClass] containsObject:[view class]]) {
    //        return NO;
    //    } else if (![[self subviews] containsObject:view]) { /** 非自身子视图 */
    //        return NO;
    //    }
    return [super touchesShouldCancelInContentView:view];
}

@end
