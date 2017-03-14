//
//  LFClippingView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFClippingView.h"

@interface LFClippingView () <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *zoomingView;
@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation LFClippingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.backgroundColor = [UIColor blueColor];
    self.clipsToBounds = NO;
    self.delegate = self;
    self.maximumZoomScale = 5.0f;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.alwaysBounceHorizontal = YES;
    self.alwaysBounceVertical = YES;
    
    UIView *zoomingView = [[UIView alloc] initWithFrame:self.bounds];
    zoomingView.backgroundColor = [UIColor clearColor];
    [self addSubview:zoomingView];
    self.zoomingView = zoomingView;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.zoomingView.bounds];
    imageView.backgroundColor = [UIColor clearColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.zoomingView addSubview:imageView];
    self.imageView = imageView;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.zoomingView.frame = self.bounds;
    self.imageView.frame = self.zoomingView.bounds;
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    [self.imageView setImage:image];
    [self setZoomScale:1.f];
}

#pragma mark - UIScrollViewDelegate

#pragma mark - 重写父类方法

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{    
    
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
   
    return [super touchesShouldCancelInContentView:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.zoomingView) { /** 不触发下一层UI响应 */
        return self;
    }
    return view;
}

@end
