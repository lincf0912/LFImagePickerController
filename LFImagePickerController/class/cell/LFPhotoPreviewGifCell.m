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

@implementation LFPhotoPreviewGifCell

/** 重置视图 */
- (void)subViewReset
{
    [super subViewReset];
    [[LFGifPlayerManager shared] stopGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
}
/** 设置数据 */
- (void)subViewSetModel:(LFAsset *)model completeHandler:(void (^)(id data,NSDictionary *info,BOOL isDegraded))completeHandler progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler
{
    [super subViewSetModel:model completeHandler:completeHandler progressHandler:progressHandler];
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
            }
            
        } progressHandler:progressHandler networkAccessAllowed:YES];
    }
}

- (void)willDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        [self setModel:self.model];
    }
}

- (void)didEndDisplayCell
{
    if (self.model.subType == LFAssetSubMediaTypeGIF) { /** GIF图片处理 */
        [[LFGifPlayerManager shared] stopGIFWithKey:[NSString stringWithFormat:@"%zd", [self.model hash]]];
    }
}

@end
