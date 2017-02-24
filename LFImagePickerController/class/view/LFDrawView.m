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

/** 实际笔画 */
@property (nonatomic, strong) NSMutableArray *allLineArray;
/** 临时笔画 */
@property (nonatomic, strong) NSMutableArray *lineArray;

@end

@implementation LFDrawView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lineWidth = 3.f;
        _lineColor = [UIColor redColor];
        _allLineArray = [@[] mutableCopy];
        _lineArray = [@[] mutableCopy];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.drawBegan) self.drawBegan();
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
    //绘制
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    LFDrawBezierPath *path = self.lineArray.lastObject;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [path addLineToPoint:point];
    //重新绘制
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event{
    if (self.drawEnded) self.drawEnded();
}

- (void)drawRect:(CGRect)rect{
    //遍历数组，绘制曲线
    for (LFDrawBezierPath *path in self.allLineArray) {
        [path.color setStroke];
        [path setLineCapStyle:kCGLineCapRound];
        [path stroke];
    }
    for (LFDrawBezierPath *path in self.lineArray) {
        [path.color setStroke];
        [path setLineCapStyle:kCGLineCapRound];
        [path stroke];
    }
}

/** 是否可撤销 */
- (BOOL)canUndo
{
    return self.lineArray.count || self.allLineArray.count;
}

//撤销
- (void)undo
{
    if (self.lineArray.count) {
        [self.lineArray removeLastObject];
    } else {
        [self.allLineArray removeLastObject];
    }
    [self setNeedsDisplay];
}

/** 是否发生改变 */
- (BOOL)isChanged
{
    return self.lineArray.count;
}
/** 提交 */
- (void)commit
{
    [self.allLineArray addObjectsFromArray:[self.lineArray copy]];
    [self.lineArray removeAllObjects];
}
/** 回滚 */
- (void)rollback
{
    [self.lineArray removeAllObjects];
    [self setNeedsDisplay];
}

@end
