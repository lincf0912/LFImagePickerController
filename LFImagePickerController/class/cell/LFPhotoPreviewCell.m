//
//  LFPhotoPreviewCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"
#import "UIView+LFFrame.h"
#import "LFAssetManager.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

@interface LFProgressView : UIView

@property (nonatomic, assign) double progress;
@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end

@implementation LFProgressView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _progressLayer = [CAShapeLayer layer];
        _progressLayer.fillColor = [[UIColor clearColor] CGColor];
        _progressLayer.strokeColor = [[UIColor whiteColor] CGColor];
        _progressLayer.opacity = 1;
        _progressLayer.lineCap = kCALineCapRound;
        _progressLayer.lineWidth = 5;
        
        [_progressLayer setShadowColor:[UIColor blackColor].CGColor];
        [_progressLayer setShadowOffset:CGSizeMake(1, 1)];
        [_progressLayer setShadowOpacity:0.5];
        [_progressLayer setShadowRadius:2];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    CGFloat radius = rect.size.width / 2;
    CGFloat startA = - M_PI_2;
    CGFloat endA = - M_PI_2 + M_PI * 2 * _progress;
    _progressLayer.frame = self.bounds;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startA endAngle:endA clockwise:YES];
    _progressLayer.path =[path CGPath];
    
    [_progressLayer removeFromSuperlayer];
    [self.layer addSublayer:_progressLayer];
}

- (void)setProgress:(double)progress {
    _progress = progress;
    [self setNeedsDisplay];
}

@end



@interface LFPhotoPreviewCell () <UIScrollViewDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *imageContainerView;
@property (nonatomic, strong) LFProgressView *progressView;
@end

@implementation LFPhotoPreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = CGRectMake(10, 0, self.width - 20, self.height);
        _scrollView.bouncesZoom = YES;
        _scrollView.maximumZoomScale = 2.5;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
        _scrollView.canCancelContentTouches = YES;
        _scrollView.alwaysBounceVertical = NO;
        [self.contentView addSubview:_scrollView];
        
        _imageContainerView = [[UIView alloc] init];
        _imageContainerView.clipsToBounds = YES;
        _imageContainerView.contentMode = UIViewContentModeScaleAspectFill;
        [_scrollView addSubview:_imageContainerView];
        
        _imageView = [[UIImageView alloc] init];
//        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        [_imageContainerView addSubview:_imageView];
        
        UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:tap1];
        UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        tap2.numberOfTapsRequired = 2;
        [tap1 requireGestureRecognizerToFail:tap2];
        [self addGestureRecognizer:tap2];
    }
    return self;
}

- (UIImage *)previewImage
{
    return self.imageView.image;
}

- (void)setPreviewImage:(UIImage *)previewImage
{
    self.imageView.image = previewImage;
    [self resizeSubviews];
}

- (void)setModel:(LFAsset *)model
{
    _model = model;
    /** 优先显示编辑图片 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit.editPreviewImage) {
        self.previewImage = photoEdit.editPreviewImage;
    } else if (model.asset == nil) { /** 显示自定义图片 */
        self.previewImage = model.previewImage;
    } else {
        /** 如果已被设置图片，忽略这次图片获取 */
        if (self.previewImage) {
            return;
        }
        [[LFAssetManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([model isEqual:self.model]) {
                self.previewImage = photo;
                _progressView.hidden = YES;
                if (self.imageProgressUpdateBlock) {
                    self.imageProgressUpdateBlock(1);
                }
            }
        } progressHandler:^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            if ([model isEqual:self.model]) {
                _progressView.hidden = NO;
                [self bringSubviewToFront:_progressView];
                progress = progress > 0.02 ? progress : 0.02;;
                _progressView.progress = progress;
                if (self.imageProgressUpdateBlock) {
                    self.imageProgressUpdateBlock(progress);
                }
            }
        } networkAccessAllowed:YES];
    }
}

- (void)recoverSubviews {
    [self resizeSubviews];
}


- (void)resizeSubviews {
    _imageContainerView.origin = CGPointZero;
    _imageContainerView.width = self.scrollView.width;
    
    UIImage *image = _imageView.image;
    if (image) {
        if (image.size.height / image.size.width > self.height / self.scrollView.width) {
            _imageContainerView.height = floor(image.size.height / (image.size.width / self.scrollView.width));
        } else {
            CGFloat height = image.size.height / image.size.width * self.scrollView.width;
            if (height < 1 || isnan(height)) height = self.height;
            height = floor(height);
            _imageContainerView.height = height;
            _imageContainerView.centerY = self.height / 2;
        }
        if (_imageContainerView.height > self.height && _imageContainerView.height - self.height <= 1) {
            _imageContainerView.height = self.height;
        }
        CGFloat contentSizeH = MAX(_imageContainerView.height, self.height);
        _scrollView.contentSize = CGSizeMake(self.scrollView.width, contentSizeH);
        [_scrollView scrollRectToVisible:self.bounds animated:NO];
        _scrollView.alwaysBounceVertical = _imageContainerView.height <= self.height ? NO : YES;
        _imageView.frame = _imageContainerView.bounds;
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.model = nil;
    self.imageView.image = nil;
}

#pragma mark - UITapGestureRecognizer Event

- (void)doubleTap:(UITapGestureRecognizer *)tap {
    if (_scrollView.zoomScale > 1.0) {
        _scrollView.contentInset = UIEdgeInsetsZero;
        [_scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [tap locationInView:self.imageView];
        CGFloat newZoomScale = _scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [_scrollView zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
    }
}

- (void)singleTap:(UITapGestureRecognizer *)tap {
    if (self.singleTapGestureBlock) {
        self.singleTapGestureBlock();
    }
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageContainerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshImageContainerViewCenter];
}

#pragma mark - Private

- (void)refreshImageContainerViewCenter {
    CGFloat offsetX = (_scrollView.width > _scrollView.contentSize.width) ? ((_scrollView.width - _scrollView.contentSize.width) * 0.5) : 0.0;
    CGFloat offsetY = (_scrollView.height > _scrollView.contentSize.height) ? ((_scrollView.height - _scrollView.contentSize.height) * 0.5) : 0.0;
    self.imageContainerView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
}

@end

