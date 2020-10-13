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
@property (nonatomic, assign) CGFloat imageWidth;
@property (nonatomic, assign) CGFloat imageHeight;

@property (nonatomic, assign) BOOL waitForReadyToPlay;

@end

@implementation LFPhotoPreviewGifCell


- (UIImage *)previewImage
{
    if (self.imageData) {
        return [UIImage LF_imageWithImageData:self.imageData];
    }
    return nil;
}

- (void)setPreviewImage:(UIImage *)previewImage
{
    [super setPreviewImage:previewImage];
    [self.imageView startAnimating];
}

/** 图片大小 */
- (CGSize)subViewImageSize
{
    if (self.imageWidth && self.imageHeight) {
        return CGSizeMake(self.imageWidth, self.imageHeight);
    }
    return self.imageView.image.size;
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
        // 先获取缩略图
        PHImageRequestID imageRequestID = [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:self.bounds.size.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (completeHandler) {
                completeHandler(photo, info, YES);
            }
        }];
        // 获取原图
        [[LFAssetManager manager] getPhotoDataWithAsset:model.asset completion:^(NSData *data, NSDictionary *info, BOOL isDegraded) {
            
            if ([model isEqual:self.model]) {
                
                [[LFAssetManager manager] cancelImageRequest:imageRequestID];
                
                if (self.waitForReadyToPlay) {
                    self.waitForReadyToPlay = NO;
                    NSString *modelKey = [NSString stringWithFormat:@"%zd", [self.model hash]];
                    [[LFGifPlayerManager shared] transformGifDataToSampBufferRef:data key:modelKey execution:^(CGImageRef imageData, NSString *key) {
                        if ([modelKey isEqualToString:key]) {
                            self.imageView.layer.contents = (__bridge id _Nullable)(imageData);
                        }
                    } fail:^(NSString *key) {
                    }];
                }
                self.imageData = data;
                // gif
                if(data.length > 9) {
                    // gif 6~9 位字符代表尺寸
                    short w1 = 0, w2 = 0;
                    [data getBytes:&w1 range:NSMakeRange(6, 1)];
                    [data getBytes:&w2 range:NSMakeRange(7, 1)];
                    short w = w1 + (w2 << 8);
                    short h1 = 0, h2 = 0;
                    [data getBytes:&h1 range:NSMakeRange(8, 1)];
                    [data getBytes:&h2 range:NSMakeRange(9, 1)];
                    short h = h1 + (h2 << 8);
                    self.imageWidth = w;
                    self.imageHeight = h;
                }
                self.isFinalData = YES;
                /** 这个方式加载GIF内存使用非常高 */
                //self.previewImage = [UIImage LF_imageWithImageData:data];
                [self resizeSubviews]; // 刷新subview的位置。
            }
            
        } progressHandler:progressHandler networkAccessAllowed:YES];
    } else {
        [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
    }
}

- (void)didDisplayCell
{
    [super didDisplayCell];
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        if (self.imageData) {
            NSString *modelKey = [NSString stringWithFormat:@"%zd", [self.model hash]];
            if ([[LFGifPlayerManager shared] containGIFKey:modelKey]) {
                [[LFGifPlayerManager shared] resumeGIFWithKey:modelKey execution:^(CGImageRef imageData, NSString *key) {
                    if ([modelKey isEqualToString:key]) {
                        self.imageView.layer.contents = (__bridge id _Nullable)(imageData);
                    }
                } fail:^(NSString *key) {
                    
                }];
            } else {
                [[LFGifPlayerManager shared] transformGifDataToSampBufferRef:self.imageData key:modelKey execution:^(CGImageRef imageData, NSString *key) {
                    if ([modelKey isEqualToString:key]) {
                        self.imageView.layer.contents = (__bridge id _Nullable)(imageData);
                    }
                } fail:^(NSString *key) {
                }];                
            }
        } else {
            _waitForReadyToPlay = YES;
        }
    }
}

- (void)willEndDisplayCell
{
    [super willEndDisplayCell];
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        _waitForReadyToPlay = NO;
        [[LFGifPlayerManager shared] suspendGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
    }
}

- (void)didEndDisplayCell
{
    [super didEndDisplayCell];
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        _waitForReadyToPlay = NO;
        [[LFGifPlayerManager shared] stopGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
    }
}

@end
