//
//  NSString+LFExtendedStringDrawing.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2020/9/29.
//  Copyright © 2020 LamTsanFeng. All rights reserved.
//

#import "NSString+LFExtendedStringDrawing.h"

@implementation NSString (LFExtendedStringDrawing)

- (CGSize)lf_boundingSizeWithSize:(CGSize)size font:(UIFont *)font
{
    // 换行符
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
    return [self lf_boundingSizeWithSize:size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName: paragraphStyle} context:nil];
}

- (CGSize)lf_boundingSizeWithSize:(CGSize)size attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes
{
    return [self lf_boundingSizeWithSize:size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:attributes context:nil];
}

- (CGSize)lf_boundingSizeWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes
{
    return [self lf_boundingSizeWithSize:size options:options attributes:attributes context:nil];
}

- (CGSize)lf_boundingSizeWithSize:(CGSize)size options:(NSStringDrawingOptions)options attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes context:(nullable NSStringDrawingContext *)context
{
    return [self boundingRectWithSize:size options:options attributes:attributes context:context].size;
}

@end
