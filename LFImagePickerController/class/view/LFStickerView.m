//
//  LFStickerView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFStickerView.h"
#import "LFMovingView.h"
#import "UIView+LFFrame.h"

@interface LFStickerView ()

@end

@implementation LFStickerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    self.userInteractionEnabled = YES;
    self.clipsToBounds = YES;
}

#pragma mark - 解除响应事件
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self ? nil : view);
}

- (void)setTapEnded:(void (^)(UIView *))tapEnded
{
    _tapEnded = tapEnded;
    for (LFMovingView *subView in self.subviews) {
        if ([subView isKindOfClass:[LFMovingView class]]) {
            [subView setTapEnded:tapEnded];
        }
    }
}

/** 创建可移动视图 */
- (LFMovingView *)createBaseMovingView:(UIView *)view
{
    LFMovingView *movingView = [[LFMovingView alloc] initWithView:view];
    movingView.center = CGPointMake(self.width/2, self.height/2);
    
    [LFMovingView setActiveEmoticonView:movingView];
    
    [self addSubview:movingView];
    
    if (self.tapEnded) {
        [movingView setTapEnded:self.tapEnded];
    }
    
    return movingView;
}

/** 创建图片 */
- (void)createImage:(UIImage *)image
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    LFMovingView *movingView = [self createBaseMovingView:imageView];
    movingView.maxScale = 2.f;
    CGFloat ratio = MIN( (0.2 * self.width) / movingView.width, (0.2 * self.height) / movingView.height);
    [movingView setScale:ratio];
}

/** 创建文字 */
- (void)createText:(NSString *)text
{
    CGFloat fontSize = 50.f;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    NSDictionary *attribDict = @{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:attribDict context:nil].size;
    
    textSize.width += 20;
    textSize.height += 10;
    UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){CGPointZero, textSize}];
    label.text = text;
    label.font = font;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 1/fontSize;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    //阴影透明度
    label.layer.shadowOpacity = 1.0;
    //阴影宽度
    label.layer.shadowRadius = 3.0;
    //阴影颜色
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    //映影偏移
    label.layer.shadowOffset = CGSizeMake(1, 1);
    
    LFMovingView *movingView = [self createBaseMovingView:label];
    CGFloat ratio = MIN( (0.8 * self.width) / movingView.width, (0.8 * self.height) / movingView.height);
    [movingView setScale:ratio];
}

- (id)copyWithZone:(NSZone *)zone{
    LFStickerView *stickerView = [[[self class] allocWithZone:zone] init];
    stickerView.frame = self.frame;
    for (LFMovingView *movingView in self.subviews) {
        if ([movingView.view isKindOfClass:[UIImageView class]]) { /** 图片贴图 */
            [stickerView createImage:((UIImageView *)movingView.view).image];
        } else if ([movingView.view isKindOfClass:[UILabel class]]) { /** 文字贴图 */
            [stickerView createText:((UILabel *)movingView.view).text];
        }
    }
    
    return stickerView;
}

@end
