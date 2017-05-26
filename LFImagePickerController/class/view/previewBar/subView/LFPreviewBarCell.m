//
//  LFPreviewBarCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPreviewBarCell.h"
#import "UIView+LFFrame.h"

#import "LFAssetManager.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

@interface LFPreviewBarCell ()

@property (nonatomic, weak) UIImageView *imageView;

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
    [self addSubview:imageView];
    self.imageView = imageView;
    
    UIView *maskHitView = [[UIView alloc] initWithFrame:self.bounds];
    maskHitView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    maskHitView.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    maskHitView.hidden = YES;
    [self addSubview:maskHitView];
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
        self.imageView.image = asset.previewImage;
    }  else {
        [[LFAssetManager manager] getPhotoWithAsset:asset.asset photoWidth:self.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([asset.asset isEqual:self.asset.asset]) {
                self.imageView.image = photo;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
    }
    
    self.maskHitView.hidden = asset.isSelected;
}

@end
