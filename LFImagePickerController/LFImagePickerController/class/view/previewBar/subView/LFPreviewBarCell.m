//
//  LFPreviewBarCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPreviewBarCell.h"
#import "LFImagePickerHeader.h"

#import "LFAssetManager.h"
#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"
#import "LFVideoEditManager.h"
#import "LFVideoEdit.h"
#endif

@interface LFPreviewBarCell ()

/** 展示图片 */
@property (nonatomic, weak) UIImageView *imageView;
/** 编辑标记 */
@property (weak, nonatomic) UIImageView *editMaskImageView;
/** 视频标记 */
@property (weak, nonatomic) UIImageView *videoMaskImageView;
/** 遮罩 */
@property (nonatomic, weak) UIView *maskHitView;

@end

@implementation LFPreviewBarCell

+ (NSString *)identifier
{
    return NSStringFromClass([self class]);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)customInit
{
    self.backgroundColor = [UIColor clearColor];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.contentView addSubview:imageView];
    self.imageView = imageView;
    
    UIImageView *editMaskImageView = [[UIImageView alloc] init];
    CGRect editFrame = CGRectMake(5, 5, 13.5, 11);
    editMaskImageView.frame = editFrame;
    [editMaskImageView setImage:bundleImageNamed(@"contacts_add_myablum")];
    editMaskImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:editMaskImageView];
    _editMaskImageView = editMaskImageView;
    
    UIImageView *videoMaskImageView = [[UIImageView alloc] init];
    CGRect videoFrame = CGRectMake(5, self.frame.size.height - 11 - 5, 18, 11);
    videoMaskImageView.frame = videoFrame;
    [videoMaskImageView setImage:bundleImageNamed(@"fileicon_video_wall")];
    videoMaskImageView.contentMode = UIViewContentModeScaleAspectFit;
    videoMaskImageView.hidden = YES;
    [self.contentView addSubview:videoMaskImageView];
    _videoMaskImageView = videoMaskImageView;
    
    
    UIView *maskHitView = [[UIView alloc] initWithFrame:self.bounds];
    maskHitView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    maskHitView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    maskHitView.hidden = YES;
    [self.contentView addSubview:maskHitView];
    self.maskHitView = maskHitView;
}

- (void)setAsset:(LFAsset *)asset
{
    _asset = asset;
    
    BOOL hiddenEditMask = YES;
    if (self.asset.type == LFAssetMediaTypePhoto) {
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:asset];
        if (photoEdit.editPosterImage) {
            self.imageView.image = photoEdit.editPosterImage;
            hiddenEditMask = NO;
        } else {
#endif
            [self getAssetImage:asset];
#ifdef LF_MEDIAEDIT
        }
#endif
        /** 显示编辑标记 */
        self.editMaskImageView.hidden = hiddenEditMask;
    } else if (self.asset.type == LFAssetMediaTypeVideo) {
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:asset];
        if (videoEdit.editPosterImage) {
            self.imageView.image = videoEdit.editPosterImage;
            hiddenEditMask = NO;
        } else {
#endif
            [self getAssetImage:asset];
#ifdef LF_MEDIAEDIT
        }
#endif
        /** 显示编辑标记 */
        self.editMaskImageView.hidden = hiddenEditMask;
    }
    /** 显示视频标记 */
    if (_asset.type == LFAssetMediaTypeVideo) {
        self.videoMaskImageView.hidden = NO;
    } else {
        self.videoMaskImageView.hidden = YES;
    }
}

- (void)setIsSelectedAsset:(BOOL)isSelectedAsset
{
    _isSelectedAsset = isSelectedAsset;
    /** 显示遮罩 */
    self.maskHitView.hidden = isSelectedAsset;
}


- (void)getAssetImage:(LFAsset *)asset
{
    if (asset.thumbnailImage) { /** 显示自定义图片 */
        self.imageView.image = (asset.previewImage.images.count > 0 ? asset.previewImage.images.firstObject : asset.thumbnailImage);
    }  else {
        [[LFAssetManager manager] getPhotoWithAsset:asset.asset photoWidth:self.frame.size.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([asset.asset isEqual:self.asset.asset]) {
                self.imageView.image = photo;
            } else {
                self.imageView.image = nil;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
    }
}
@end
