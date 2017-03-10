//
//  LFSplashView.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/28.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFSplashView.h"
#import "LFMaskLayer.h"
#import "UIImage+LFCommon.h"

@interface LFSplashView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}

/** 马赛克 */
@property (nonatomic, strong) CALayer *imageLayer_mosaic;
@property (nonatomic, strong) LFMaskLayer *mosaicLayer;
/** 高斯模糊 */
@property (nonatomic, strong) CALayer *imageLayer_blurry;
@property (nonatomic, strong) LFMaskLayer *blurLayer;

//设置手指的涂抹路径
@property (nonatomic, strong) NSMutableArray *lineArray;
/** 线粗 */
@property (nonatomic, assign) CGFloat lineWidth;

@end

@implementation LFSplashView

- (void)reset
{
    _state = LFSplashStateType_Mosaic;
    self.splashBegan = nil;
    self.splashEnded = nil;
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
    
    //添加layer（imageLayer_mosaic）到self上
    self.imageLayer_mosaic = [CALayer layer];
    self.imageLayer_mosaic.frame = self.bounds;
    [self.layer addSublayer:self.imageLayer_mosaic];
    
    self.mosaicLayer = [[LFMaskLayer alloc] init];
    self.mosaicLayer.frame = self.bounds;
    [self.layer addSublayer:self.mosaicLayer];
    
    self.imageLayer_mosaic.mask = self.mosaicLayer;
    
    /** 高斯模糊 */
    self.imageLayer_blurry = [CALayer layer];
    self.imageLayer_blurry.frame = self.bounds;
    [self.layer addSublayer:self.imageLayer_blurry];
    
    self.blurLayer = [[LFMaskLayer alloc] init];
    self.blurLayer.frame = self.bounds;
    [self.layer addSublayer:self.blurLayer];
    
    self.imageLayer_blurry.mask = self.blurLayer;
    
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.imageLayer_mosaic.frame = self.bounds;
    self.mosaicLayer.frame = self.bounds;
    self.imageLayer_blurry.frame = self.bounds;
    self.blurLayer.frame = self.bounds;
}

/** 设置图片 */
- (void)setImage:(UIImage *)image mosaicLevel:(NSUInteger)level
{
    //底图
    _image = image;
    _level = level;
    self.imageLayer_mosaic.contents = (id)[_image transToMosaicLevel:level].CGImage;
    self.imageLayer_blurry.contents = (id)[_image transToBlurLevel:level].CGImage;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (touches.allObjects.count == 1) {
        _isWork = NO;
        _isBegan = YES;
        
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        LFBlurBezierPath *path = [LFBlurBezierPath new];
        [path setLineCapStyle:kCGLineCapRound];
        [path setLineJoinStyle:kCGLineJoinRound];
        path.lineWidth = _lineWidth;
        [path moveToPoint:point];
        [self.lineArray addObject:@1];
        
        LFBlurBezierPath *mosaicPath = [path copy];
        mosaicPath.isClear = (self.state != LFSplashStateType_Mosaic);
        [self.mosaicLayer.lineArray addObject:mosaicPath];
        
        LFBlurBezierPath *blurryPath = [path copy];
        blurryPath.isClear = (self.state != LFSplashStateType_Blurry);
        [self.blurLayer.lineArray addObject:blurryPath];
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
        
        UIBezierPath *mosaicPath = self.mosaicLayer.lineArray.lastObject;
        [mosaicPath addLineToPoint:point];
        
        UIBezierPath *blurryPath = self.blurLayer.lineArray.lastObject;
        [blurryPath addLineToPoint:point];
        
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
    [self.mosaicLayer setNeedsDisplay];
    [self.blurLayer setNeedsDisplay];
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
    [self.mosaicLayer.lineArray removeLastObject];
    [self.blurLayer.lineArray removeLastObject];
    [self drawLine];
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone{
    LFSplashView *splashView = [[[self class] allocWithZone:zone] init];
    splashView.frame = self.frame;
    splashView.state = self.state;
    [splashView setImage:self.image mosaicLevel:self.level];
    splashView.lineArray = [self.lineArray mutableCopy];
    splashView.mosaicLayer.lineArray = [self.mosaicLayer.lineArray mutableCopy];
    splashView.blurLayer.lineArray = [self.blurLayer.lineArray mutableCopy];
    [splashView drawLine];
    
    return splashView;
}

@end
