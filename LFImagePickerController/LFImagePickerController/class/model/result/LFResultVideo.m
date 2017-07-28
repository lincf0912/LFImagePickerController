//
//  LFResultVideo.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultVideo.h"

@implementation LFResultVideo

- (void)setCoverImage:(UIImage *)coverImage
{
    _coverImage = coverImage;
}

- (void)setData:(NSData *)data
{
    _data = data;
}

- (void)setDuration:(NSTimeInterval)duration
{
    _duration = duration;
}

- (void)setUrl:(NSURL *)url
{
    _url = url;
}

@end
