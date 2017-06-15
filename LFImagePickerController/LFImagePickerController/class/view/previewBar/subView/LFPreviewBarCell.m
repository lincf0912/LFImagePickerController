//
//  LFPreviewBarCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPreviewBarCell.h"
#import "UIView+LFFrame.h"
#import "LFImagePickerHeader.h"

#import "LFAssetManager.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

@interface LFPreviewBarCell ()

/** 展示图片 */
@property (nonatomic, weak) UIImageView *imageView;
/** 编辑标记 */
@property (weak, nonatomic) UIImageView *editMaskImageView;
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
    CGRect frame = CGRectMake(5, self.height - 22 - 5, 22, 22);
    editMaskImageView.frame = frame;
    [editMaskImageView setImage:bundleImageNamed(@"contacts_add_myablum.png")];
    editMaskImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:editMaskImageView];
    _editMaskImageView = editMaskImageView;
    
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
    
    /** 优先显示编辑图片 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:asset];
    if (photoEdit.editPosterImage) {
        self.imageView.image = photoEdit.editPosterImage;
    } else if (asset.previewImage) { /** 显示自定义图片 */
        self.imageView.image = (asset.previewImage.images.count > 0 ? asset.previewImage.images.firstObject : asset.previewImage);
    }  else {
        [[LFAssetManager manager] getPhotoWithAsset:asset.asset photoWidth:self.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([asset.asset isEqual:self.asset.asset]) {
                self.imageView.image = photo;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
    }
    /** 显示编辑标记 */
    self.editMaskImageView.hidden = (photoEdit.editPosterImage == nil);
    /** 显示遮罩 */
    self.maskHitView.hidden = asset.isSelected;
}

@end
