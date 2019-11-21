//
//  LFPhotoPreviewCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/14.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"
#import "UIImage+LFCommon.h"
#import "LFAssetManager.h"
#import "LFImagePickerHeader.h"

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"
#endif

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
//@property (nonatomic, strong) LFProgressView *progressView;
@property (nonatomic, strong) UITapGestureRecognizer *tap1;
@property (nonatomic, strong) UITapGestureRecognizer *tap2;

@end

@implementation LFPhotoPreviewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
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
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_imageContainerView addSubview:_imageView];
        
        UIView *view = [self subViewInitDisplayView];
        if (view) {
            view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_imageContainerView addSubview:view];
        }
        
        _tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [self addGestureRecognizer:_tap1];
        _tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        _tap2.numberOfTapsRequired = 2;
        [_tap1 requireGestureRecognizerToFail:_tap2];
        [self addGestureRecognizer:_tap2];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self resizeSubviews];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self subViewReset];
    _model = nil;
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
    if (model.type == LFAssetMediaTypePhoto) {
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
        if (photoEdit.editPreviewImage) {
            self.previewImage = photoEdit.editPreviewImage;
        } else
#endif
            if (model.previewImage) { /** 显示自定义图片 */
                self.previewImage = model.previewImage;
            } else {
                
                void (^completion)(id data,NSDictionary *info,BOOL isDegraded) = ^(id data,NSDictionary *info,BOOL isDegraded){
                    if ([model isEqual:self.model]) {
                        if ([data isKindOfClass:[UIImage class]]) { /** image */
                            self.previewImage = (UIImage *)data;
                        } else if ([data isKindOfClass:[NSData class]]) {
                            self.previewImage = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
                        }
                        //                _progressView.hidden = YES;
                    }
                };
                
                //        void (^progressHandler)(double progress, NSError *error, BOOL *stop, NSDictionary *info) = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info){
                //            if ([model isEqual:self.model]) {
                //                _progressView.hidden = NO;
                //                [self bringSubviewToFront:_progressView];
                //                progress = progress > 0.02 ? progress : 0.02;;
                //                _progressView.progress = progress;
                //            }
                //        };
                
                
                [self subViewSetModel:model completeHandler:completion progressHandler:nil];
            }
    } else {
        void (^completion)(id data,NSDictionary *info,BOOL isDegraded) = ^(id data,NSDictionary *info,BOOL isDegraded){
            if ([model isEqual:self.model]) {
                if ([data isKindOfClass:[UIImage class]]) { /** image */
                    self.previewImage = (UIImage *)data;
                } else if ([data isKindOfClass:[NSData class]]) {
                    self.previewImage = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
                }
                //                _progressView.hidden = YES;
            }
        };
        
        [self subViewSetModel:model completeHandler:completion progressHandler:nil];
    }
}

- (void)willDisplayCell
{
    
}

- (void)didEndDisplayCell
{
    
}

- (void)resizeSubviews {
    [self.scrollView setZoomScale:1.f];
    _imageContainerView.frame = self.scrollView.bounds;
    
    CGSize imageSize = [self subViewImageSize];
    
    if (!CGSizeEqualToSize(imageSize, CGSizeZero)) {


        UIEdgeInsets ios11Safeinsets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            ios11Safeinsets = self.safeAreaInsets;
        }
        CGSize scrollViewSize = self.scrollView.frame.size;
        scrollViewSize.height -= (ios11Safeinsets.top+ios11Safeinsets.bottom);
        /** 定义最小尺寸,判断为长图，则使用放大处理 */
        CGSize newSize = [UIImage lf_scaleImageSizeBySize:imageSize targetSize:scrollViewSize isBoth:NO];
        
        BOOL isLongImage = NO;
        if (self.model.type == LFAssetMediaTypePhoto) {
//            if ([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height) {
//                isLongImage = scrollViewSize.width > newSize.width;
//            } else {
//                isLongImage = newSize.width < self.bounds.size.height * 0.6;
//            }
            isLongImage = lf_isPiiic(newSize);
            if (isLongImage) { /** 长图 */
                newSize = [UIImage lf_imageSizeBySize:imageSize maxWidth:self.scrollView.frame.size.width];
            }
        }
        
        CGRect _imageContainerViewRect = _imageContainerView.frame;
        _imageContainerViewRect.size = newSize;
        if (isLongImage && newSize.height > self.scrollView.frame.size.height-(ios11Safeinsets.top+ios11Safeinsets.bottom)) {
            _imageContainerViewRect.origin = CGPointMake(0, 0);
            _imageContainerView.frame = _imageContainerViewRect;
            self.scrollView.showsVerticalScrollIndicator = YES;
            [self.scrollView setContentOffset:CGPointMake(0, -ios11Safeinsets.top)];
        } else {
            _imageContainerView.frame = _imageContainerViewRect;
            _imageContainerView.center = self.scrollView.center;
            self.scrollView.showsVerticalScrollIndicator = NO;
        }
        self.scrollView.contentSize = _imageContainerView.frame.size;
        
        _imageView.frame = _imageContainerView.bounds;
        UIView *view = [self subViewInitDisplayView];
        view.frame = _imageContainerView.bounds;
    }
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
    if ([self.delegate respondsToSelector:@selector(lf_photoPreviewCellSingleTapHandler:)]) {
        [self.delegate lf_photoPreviewCellSingleTapHandler:self];
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
    UIEdgeInsets ios11Safeinsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        ios11Safeinsets = self.safeAreaInsets;
    }
    if (self.imageContainerView.frame.size.height < self.scrollView.frame.size.height-(ios11Safeinsets.top+ios11Safeinsets.bottom)) {
        CGFloat offsetX = (_scrollView.frame.size.width > _scrollView.contentSize.width) ? ((_scrollView.frame.size.width - _scrollView.contentSize.width) * 0.5) : 0.0;
        CGFloat offsetY = (_scrollView.frame.size.height > _scrollView.contentSize.height) ? ((_scrollView.frame.size.height - _scrollView.contentSize.height) * 0.5) : 0.0;
        self.imageContainerView.center = CGPointMake(_scrollView.contentSize.width * 0.5 + offsetX, _scrollView.contentSize.height * 0.5 + offsetY);
    }
}

/** 创建显示视图 */
- (UIView *)subViewInitDisplayView
{
    return nil;
}

/** 图片大小 */
- (CGSize)subViewImageSize
{
    return self.imageView.image.size;
}

/** 重置视图 */
- (void)subViewReset
{
    self.imageView.image = nil;
}

/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    /** 如果已被设置图片，忽略这次图片获取 */
    if (self.previewImage == nil) {
        /** 普通图片处理 */
        if (model.type == LFAssetMediaTypePhoto) {
            /** 图片使用data的加载方式，透明背景的png使用image的加载方式会丢失透明通道。 */
            [[LFAssetManager manager] getPhotoDataWithAsset:model.asset completion:completeHandler progressHandler:progressHandler networkAccessAllowed:YES];
        } else {
            [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:[UIScreen mainScreen].bounds.size.width completion:completeHandler progressHandler:progressHandler networkAccessAllowed:YES];
;
        }
    }
}


@end

