//
//  LFSplashView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFSplashView.h"
#import "UIImage+LFCommon.h"

@interface LFSplashView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
@property (nonatomic, strong) UIImageView *surfaceImageView;

@property (nonatomic, strong) CALayer *imageLayer;

@property (nonatomic, strong) CAShapeLayer *shapeLayer;
//设置手指的涂抹路径
@property (nonatomic, strong) NSMutableArray *lineArray;
/** 线粗 */
@property (nonatomic, assign) CGFloat lineWidth;

@end

@implementation LFSplashView

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
    _lineArray = [@[] mutableCopy];
    _lineWidth = 20.f;
    _state = LFSplashStateType_Mosaic;
    
    //添加imageview（surfaceImageView）到self上
    self.surfaceImageView = [[UIImageView alloc]initWithFrame:self.bounds];
    self.surfaceImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.surfaceImageView];
    //添加layer（imageLayer）到self上
    self.imageLayer = [CALayer layer];
    self.imageLayer.frame = self.bounds;
    [self.layer addSublayer:self.imageLayer];
    
    self.shapeLayer = [CAShapeLayer layer];
    self.shapeLayer.frame = self.bounds;
    self.shapeLayer.lineCap = kCALineCapRound;
    self.shapeLayer.lineJoin = kCALineJoinRound;
    self.shapeLayer.lineWidth = _lineWidth;
    self.shapeLayer.strokeColor = [UIColor blackColor].CGColor;
    self.shapeLayer.fillColor = nil;//此处设置颜色有异常效果，可以自己试试
    
    [self.layer addSublayer:self.shapeLayer];
    self.imageLayer.mask = self.shapeLayer;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.surfaceImageView.frame = self.bounds;
    self.imageLayer.frame = self.bounds;
    self.shapeLayer.frame = self.bounds;
}

/** 设置图片 */
- (void)setImage:(UIImage *)image mosaicLevel:(NSUInteger)level
{
    //底图
    _image = image;
    _level = level;
    self.imageLayer.contents = (id)[image transToMosaicLevel:level].CGImage;
    self.surfaceImageView.image = image;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        _isWork = NO;
        _isBegan = YES;
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        UIBezierPath *path = [UIBezierPath new];
        [path moveToPoint:point];
        [self.lineArray addObject:path];
    } else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        
        if (_isBegan && self.splashBegan) self.splashBegan();
        _isWork = YES;
        _isBegan = NO;

        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        UIBezierPath *path = self.lineArray.lastObject;
        [path addLineToPoint:point];
        
        [self drawLine];
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([event allTouches].count == 1){
        if (_isWork) {
            if (self.splashEnded) self.splashEnded();
        } else {
            [self undo];
        }
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)drawLine
{
    if (self.state == LFSplashStateType_Mosaic) {
        UIBezierPath *allPath = [UIBezierPath new];
        for (UIBezierPath *path in self.lineArray) {
            [allPath appendPath:path];
        }
        self.shapeLayer.path = allPath.CGPath;
    } else if (self.state == LFSplashStateType_Paint) {
        
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
    [self drawLine];
}



#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone{
    LFSplashView *splashView = [[[self class] allocWithZone:zone] init];
    splashView.frame = self.frame;
    [splashView setImage:self.image mosaicLevel:self.level];
    splashView.lineArray = [self.lineArray mutableCopy];
    [splashView drawLine];
    
    return splashView;
}

@end
