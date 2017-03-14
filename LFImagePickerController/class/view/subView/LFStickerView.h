//
//  LFStickerView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFStickerViewType) {
    LFStickerViewType_image,
    LFStickerViewType_text,
};

@interface LFStickerView : UIView <NSCopying>

/** 重置 */
- (void)reset;

/** 创建图片 */
- (void)createImage:(UIImage *)image;

/** 创建文字 */
- (void)createText:(NSString *)text;

/** 点击回调视图（UILabel/UIImageView） */
@property (nonatomic, copy) void(^tapEnded)(UIView *view, LFStickerViewType type);

@end
