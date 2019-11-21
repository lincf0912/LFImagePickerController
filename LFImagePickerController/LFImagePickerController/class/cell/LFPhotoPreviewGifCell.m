//
//  LFPhotoPreviewGifCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/6/1.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewGifCell.h"
#import "LFPhotoPreviewCell_property.h"
#import "LFAssetManager.h"

#import "LFGifPlayerManager.h"
#import "UIImage+LF_Format.h"

@interface LFPhotoPreviewGifCell ()

@property (nonatomic, strong) NSData *imageData;

@end

@implementation LFPhotoPreviewGifCell


- (UIImage *)previewImage
{
    if (self.imageData) {
        return [UIImage LF_imageWithImageData:self.imageData];
    }
    return self.imageView.image;
}

- (void)setPreviewImage:(UIImage *)previewImage
{
    [super setPreviewImage:previewImage];
    [self.imageView startAnimating];
}

/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    self.imageData = nil;
    [[LFGifPlayerManager shared] stopGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
}
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    if (model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        [[LFAssetManager manager] getPhotoDataWithAsset:model.asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
            
            if ([model isEqual:self.model]) {
                NSString *modelKey = [NSString stringWithFormat:@"%zd", [self.model hash]];
                [[LFGifPlayerManager shared] transformGifDataToSampBufferRef:data key:modelKey execution:^(CGImageRef imageData, NSString *key) {
                    if ([modelKey isEqualToString:key]) {
                        self.imageView.layer.contents = (__bridge id _Nullable)(imageData);
                    }
                } fail:^(NSString *key) {
                }];
                /** 这个方式加载GIF内存使用非常高 */
                //self.previewImage = [UIImage LF_imageWithImageData:data];
                if (completeHandler) {
                    completeHandler(data, info, isDegraded);
                }
                self.imageData = data;
            }
            
        } progressHandler:progressHandler networkAccessAllowed:YES];
    } else {
        [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
    }
}

- (void)willDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        if (self.imageData) {
            NSString *modelKey = [NSString stringWithFormat:@"%zd", [self.model hash]];
            [[LFGifPlayerManager shared] transformGifDataToSampBufferRef:self.imageData key:modelKey execution:^(CGImageRef imageData, NSString *key) {
                if ([modelKey isEqualToString:key]) {
                    self.imageView.layer.contents = (__bridge id _Nullable)(imageData);
                }
            } fail:^(NSString *key) {
            }];
        }
    }
}

- (void)didEndDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        [[LFGifPlayerManager shared] stopGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
    }
}

@end
