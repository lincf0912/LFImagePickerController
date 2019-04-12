//
//  LFPhotoPreviewCell_property.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/1.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"

@interface LFPhotoPreviewCell ()

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIScrollView *scrollView;
@property (nonatomic, readonly) UIView *imageContainerView;

@property (nonatomic, readonly) UITapGestureRecognizer *tap1;
@property (nonatomic, readonly) UITapGestureRecognizer *tap2;

@property (nonatomic, readwrite) UIImage *previewImage;

@end
