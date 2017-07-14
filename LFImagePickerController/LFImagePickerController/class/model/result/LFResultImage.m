//
//  LFResultImage.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultImage.h"

@implementation LFResultImage

 - (void)setThumbnailImage:(UIImage *)thumbnailImage
{
    _thumbnailImage = thumbnailImage;
}

- (void)setThumbnailData:(NSData *)thumbnailData
{
    _thumbnailData = thumbnailData;
}

- (void)setOriginalImage:(UIImage *)originalImage
{
    _originalImage = originalImage;
}

- (void)setOriginalData:(NSData *)originalData
{
    _originalData = originalData;
}

- (void)setSubMediaType:(LFImagePickerSubMediaType)subMediaType
{
    _subMediaType = subMediaType;
}

@end
