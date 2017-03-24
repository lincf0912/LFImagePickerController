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

NSString *const kLFStickerViewData_movingView = @"LFStickerViewData_movingView";

NSString *const kLFStickerViewData_movingView_type = @"LFStickerViewData_movingView_type";
NSString *const kLFStickerViewData_movingView_content = @"LFStickerViewData_movingView_content";

NSString *const kLFStickerViewData_movingView_center = @"LFStickerViewData_movingView_center";
NSString *const kLFStickerViewData_movingView_scale = @"LFStickerViewData_movingView_scale";
NSString *const kLFStickerViewData_movingView_rotation = @"LFStickerViewData_movingView_rotation";

#pragma mark - 带内边距的label
@interface LFStickerLabel : UILabel

@property (nonatomic, assign) UIEdgeInsets textInsets; // 控制字体与控件边界的间隙

@end

@implementation LFStickerLabel

- (instancetype)init {
    if (self = [super init]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textInsets)];
}

@end

@interface LFStickerView ()

@property (nonatomic, weak) LFMovingView *selectMovingView;

@end

@implementation LFStickerView

+ (void)LFStickerViewDeactivated
{
    [LFMovingView setActiveEmoticonView:nil];
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

- (void)setTapEnded:(void (^)(BOOL))tapEnded
{
    _tapEnded = tapEnded;
    for (LFMovingView *subView in self.subviews) {
        if ([subView isKindOfClass:[LFMovingView class]]) {
            if (tapEnded) {
                __weak typeof(self) weakSelf = self;
                [subView setTapEnded:^(LFMovingView *movingView, UIView *view, BOOL isActive) {
                    weakSelf.selectMovingView = movingView;
                    weakSelf.tapEnded(isActive);
                }];
            } else {
                [subView setTapEnded:nil];
            }
        }
    }
}

/** 激活选中的贴图 */
- (void)activeSelectStickerView
{
    [LFMovingView setActiveEmoticonView:self.selectMovingView];
}
/** 删除选中贴图 */
- (void)removeSelectStickerView
{
    [self.selectMovingView removeFromSuperview];
}

/** 获取选中贴图的内容 */
- (UIImage *)getSelectStickerImage
{
    if (self.selectMovingView.type == LFMovingViewType_imageView) {
        return ((UIImageView *)self.selectMovingView.view).image;
    }
    return nil;
}
- (NSString *)getSelectStickerText
{
    if (self.selectMovingView.type == LFMovingViewType_label) {
        return ((UILabel *)self.selectMovingView.view).text;
    }
    return nil;
}

/** 更改选中贴图内容 */
- (void)changeSelectStickerImage:(UIImage *)image
{
    if (self.selectMovingView.type == LFMovingViewType_imageView) {
        UIImageView *imageView = (UIImageView *)self.selectMovingView.view;
        imageView.image = image;
        [self.selectMovingView updateFrameWithViewSize:image.size];
    }
}
- (void)changeSelectStickerText:(NSString *)text
{
    if (self.selectMovingView.type == LFMovingViewType_label) {
        UILabel *label = (UILabel *)self.selectMovingView.view;
        label.text = text;
        CGSize textSize = [self calcTextSize:text font:label.font color:label.textColor];
        [self.selectMovingView updateFrameWithViewSize:textSize];
    }
}

/** 创建可移动视图 */
- (LFMovingView *)createBaseMovingView:(UIView *)view active:(BOOL)active
{
    LFMovingView *movingView = [[LFMovingView alloc] initWithView:view];
    /** 屏幕中心 */
    movingView.center = [self convertPoint:[UIApplication sharedApplication].keyWindow.center fromView:(UIView *)[UIApplication sharedApplication].keyWindow];
    
    if (active) {
        [LFMovingView setActiveEmoticonView:movingView];
    }
    
    [self addSubview:movingView];
    
    if (self.tapEnded) {
        __weak typeof(self) weakSelf = self;
        [movingView setTapEnded:^(LFMovingView *movingView, UIView *view, BOOL isActive) {
            weakSelf.selectMovingView = movingView;
            weakSelf.tapEnded(isActive);
        }];
    }
    
    return movingView;
}

/** 创建图片 */
- (void)createImage:(UIImage *)image
{
    LFMovingView *movingView = [self doCreateImage:image active:YES];
    CGFloat ratio = MIN( (0.2 * self.width) / movingView.width, (0.5 * self.height) / movingView.height);
    [movingView setScale:ratio];
}

- (LFMovingView *)doCreateImage:(UIImage *)image active:(BOOL)active
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    LFMovingView *movingView = [self createBaseMovingView:imageView active:active];
    movingView.maxScale = 2.f;
    
    return movingView;
}

/** 创建文字 */
- (void)createText:(NSString *)text
{
    LFMovingView *movingView = [self doCreateText:text active:YES];
    //    CGFloat ratio = MIN( (0.5 * self.width) / movingView.width, (0.5 * self.height) / movingView.height);
    [movingView setScale:0.6f];
}

- (LFMovingView *)doCreateText:(NSString *)text active:(BOOL)active
{
    CGFloat fontSize = 50.f;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIColor *color = [UIColor whiteColor];
    CGSize textSize = [self calcTextSize:text font:font color:color];
    
    CGFloat margin = 10;
    LFStickerLabel *label = [[LFStickerLabel alloc] initWithFrame:(CGRect){CGPointZero, textSize}];
    /** 设置内边距 */
    label.textInsets = UIEdgeInsetsMake(0, margin, 0, 0);
    label.numberOfLines = 0.f;
    label.text = text;
    label.font = font;
    //    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 1/fontSize;
    //    label.textAlignment = NSTextAlignmentLeft;
    label.textColor = color;
    //阴影透明度
    label.layer.shadowOpacity = 1.0;
    //阴影宽度
    label.layer.shadowRadius = 3.0;
    //阴影颜色
    label.layer.shadowColor = [UIColor blackColor].CGColor;
    //映影偏移
    label.layer.shadowOffset = CGSizeMake(1, 1);
    
    LFMovingView *movingView = [self createBaseMovingView:label active:active];
    
    return movingView;
}

- (CGSize)calcTextSize:(NSString *)text font:(UIFont *)font color:(UIColor *)color
{
    NSDictionary *attribDict = @{NSFontAttributeName:font,
                                 NSForegroundColorAttributeName:color};
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.frame), CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:attribDict context:nil].size;
    
    CGFloat margin = 10;
    textSize.width += margin*2;
    textSize.height += margin;
    
    return textSize;
}

#pragma mark  - 数据
- (NSDictionary *)data
{
    NSMutableArray *movingDatas = [@[] mutableCopy];
    for (LFMovingView *view in self.subviews) {
        if ([view isKindOfClass:[LFMovingView class]]) {
            
            id content = (view.type == LFMovingViewType_label ? ((UILabel *)view.view).text : (view.type == LFMovingViewType_imageView) ? ((UIImageView *)view.view).image : @"");
            
            [movingDatas addObject:@{kLFStickerViewData_movingView_type:@(view.type)
                                     , kLFStickerViewData_movingView_content:content
                                     , kLFStickerViewData_movingView_scale:@(view.scale)
                                     , kLFStickerViewData_movingView_rotation:@(view.rotation)
                                     , kLFStickerViewData_movingView_center:[NSValue valueWithCGPoint:view.center]}];
        }
    }
    if (movingDatas.count) {
        return @{kLFStickerViewData_movingView:[movingDatas copy]};
    }
    return nil;
}

- (void)setData:(NSDictionary *)data
{
    NSArray *movingDatas = data[kLFStickerViewData_movingView];
    if (movingDatas.count) {
        for (NSDictionary *movingData in movingDatas) {
            
            LFMovingViewType type = [movingData[kLFStickerViewData_movingView_type] integerValue];
            id content = movingData[kLFStickerViewData_movingView_content];
            CGFloat scale = [movingData[kLFStickerViewData_movingView_scale] floatValue];
            CGFloat rotation = [movingData[kLFStickerViewData_movingView_rotation] floatValue];
            CGPoint center = [movingData[kLFStickerViewData_movingView_center] CGPointValue];
            
            LFMovingView *view = nil;
            if (type == LFMovingViewType_imageView) {
                view = [self doCreateImage:content active:NO];
            } else if (type == LFMovingViewType_label) {
                view = [self doCreateText:content active:NO];
            } else {
                continue;
            }
            [view setScale:scale rotation:rotation];
            view.center = center;
        }
    }
}

@end
