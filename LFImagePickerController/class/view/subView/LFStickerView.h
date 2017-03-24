//
//  LFStickerView.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LFStickerView : UIView

/** 取消当前激活的贴图 */
+ (void)LFStickerViewDeactivated;

/** 激活选中的贴图 */
- (void)activeSelectStickerView;
/** 删除选中贴图 */
- (void)removeSelectStickerView;

/** 获取选中贴图的内容 */
- (UIImage *)getSelectStickerImage;
- (NSString *)getSelectStickerText;

/** 更改选中贴图内容 */
- (void)changeSelectStickerImage:(UIImage *)image;
- (void)changeSelectStickerText:(NSString *)text;

/** 创建图片 */
- (void)createImage:(UIImage *)image;
/** 创建文字 */
- (void)createText:(NSString *)text;

/** 数据 */
@property (nonatomic, strong) NSDictionary *data;

/** 点击回调视图（UILabel/UIImageView） */
@property (nonatomic, copy) void(^tapEnded)(BOOL isActive);

@end
