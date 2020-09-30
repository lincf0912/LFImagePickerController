//
//  NSString+LFExtendedStringDrawing.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2020/9/29.
//  Copyright © 2020 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (LFExtendedStringDrawing)

/** 计算文字大小 */
- (CGSize)lf_boundingSizeWithSize:(CGSize)size font:(UIFont *)font;


- (CGSize)lf_boundingSizeWithSize:(CGSize)size attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;
- (CGSize)lf_boundingSizeWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;
- (CGSize)lf_boundingSizeWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes context:(nullable NSStringDrawingContext *)context;

@end

NS_ASSUME_NONNULL_END
