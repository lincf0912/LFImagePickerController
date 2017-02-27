//
//  LFDrawView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFDrawView.h"

@interface LFDrawBezierPath : UIBezierPath

@property (nonatomic, strong) UIColor *color;

@end

@implementation LFDrawBezierPath


@end



@interface LFDrawView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
@property (nonatomic, strong) NSMutableArray *lineArray;

@end

@implementation LFDrawView

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
    _lineWidth = 3.f;
    _lineColor = [UIColor redColor];
    _lineArray = [@[] mutableCopy];
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    _isWork = NO;
    _isBegan = YES;
    //1、每次触摸的时候都应该去创建一条贝塞尔曲线
    LFDrawBezierPath *path = [LFDrawBezierPath new];
    //2、移动画笔
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [path moveToPoint:point];
    //设置线宽
    path.lineWidth = self.lineWidth;
    //设置颜色
    path.color = self.lineColor;//保存线条当前颜色
    
    [self.lineArray addObject:path];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    if (_isBegan && self.drawBegan) self.drawBegan();
    _isWork = YES;
    _isBegan = NO;
    LFDrawBezierPath *path = self.lineArray.lastObject;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [path addLineToPoint:point];
    //重新绘制
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    if (_isWork) {
        if (self.drawEnded) self.drawEnded();
    } else {
        [self.lineArray removeLastObject];
    }
}

- (void)drawRect:(CGRect)rect{
    //遍历数组，绘制曲线
    for (LFDrawBezierPath *path in self.lineArray) {
        [path.color setStroke];
        [path setLineCapStyle:kCGLineCapRound];
        [path stroke];
    }
}

/** 是否可撤销 */
- (BOOL)canUndo
{
    return self.lineArray.count;
}

//撤销
- (void)undo
{
    [self.lineArray removeLastObject];
    [self setNeedsDisplay];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone{
    LFDrawView *drawView = [[[self class] allocWithZone:zone] init];
    drawView.frame = self.frame;
    drawView.lineColor = self.lineColor;
    drawView.lineWidth = self.lineWidth;
    drawView.lineArray = [self.lineArray mutableCopy];
    [drawView setNeedsDisplay];
    
    return drawView;
}

@end
