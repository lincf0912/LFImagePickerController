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

@interface LFStickerView : UIView

/** 取消当前激活的贴图 */
+ (void)LFStickerViewUnAcive;

/** 创建图片 */
- (void)createImage:(UIImage *)image;

/** 创建文字 */
- (void)createText:(NSString *)text;

/** 点击回调视图（UILabel/UIImageView） */
@property (nonatomic, copy) void(^tapEnded)(UIView *view, LFStickerViewType type, BOOL isActive);

@end
