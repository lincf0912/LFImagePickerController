//
//  LFPhotoEdit.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEdit.h"
#import "LFDrawView.h"
#import "LFStickerView.h"

#import "UIImage+LFCommon.h"
#import "UIView+LFCommon.h"

@interface LFPhotoEdit ()

/** 容器 */
@property (nonatomic, weak) UIView *container;

/** 绘画 */
@property (nonatomic, strong) LFDrawView *drawView;
/** 贴图 */
@property (nonatomic, strong) LFStickerView *stickerView;
@end

@implementation LFPhotoEdit

- (void)setEditImage:(UIImage *)editPreviewImage
{
    _editPreviewImage = editPreviewImage;
    /** 设置编辑封面 */
    CGFloat width = 80.f * 2.f;
    CGSize size = [UIImage scaleImageSizeBySize:editPreviewImage.size targetSize:CGSizeMake(width, width) isBoth:NO];
    _editPosterImage = [editPreviewImage scaleToSize:size];
}

+ (NSArray <Class>*)touchClass
{
    return @[[LFDrawView class], [LFStickerView class]];
}

#pragma mark - 初始化控件容器
- (instancetype)initWithContainer:(UIView *)container
{
    self = [super init];
    if (self) {
        [self setContainer:container];
    }
    return self;
}

#pragma mark - 设置控件容器
- (void)setContainer:(UIView *)container
{
    [self clearContainer];
    _container = container;
    [_container addSubview:self.drawView];
    [_container addSubview:self.stickerView];
    
}

#pragma mark - 清空容器控件
- (void)clearContainer
{
    [_drawView removeFromSuperview];
    [_stickerView removeFromSuperview];
    
    /** 关闭功能 */
    [self setDrawEnable:NO];
    /** 清除代理 */
    self.delegate = nil;
}

/** 是否有效->有编辑过 */
- (BOOL)isWork
{
    return self.drawView.canUndo /** 绘画没有可撤销->没有绘画 */
            || self.stickerView.subviews.count /** 贴图没有子控件->没有贴图 */
    ;
}

#pragma mark - 生成编辑图片
- (BOOL)mergedContainerLayer
{
    /** 必须存在背景 */
    if (_container) {
        if (!self.isWork) { /** 无效编辑 */
            _editPosterImage = nil;
            _editPreviewImage = nil;
            return NO;
        } else {
            [self setEditImage:[_container captureImage]];
            return YES;
        }
    }
    return NO;
}

- (void)setDelegate:(id)delegate
{
    _delegate = delegate;
    /** 设置代理回调 */
    __weak typeof(self) weakSelf = self;
    _drawView.drawBegan = ^{
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(lf_photoEditDrawBegan:)]) {
            [strongSelf.delegate lf_photoEditDrawBegan:weakSelf];
        }
    };
    
    _drawView.drawEnded = ^{
        if ([weakSelf.delegate respondsToSelector:@selector(lf_photoEditDrawEnded:)]) {
            [weakSelf.delegate lf_photoEditDrawEnded:weakSelf];
        }
    };
    
    _stickerView.tapEnded = ^(UIView *view){
        if ([weakSelf.delegate respondsToSelector:@selector(lf_photoEditsticker:didSelectView:)]) {
            [weakSelf.delegate lf_photoEditsticker:weakSelf didSelectView:view];
        }
    };
}

#pragma mark - 绘画功能
/** 启用绘画功能 */
- (void)setDrawEnable:(BOOL)drawEnable
{
    _drawEnable = drawEnable;
    _drawView.userInteractionEnabled = drawEnable;
}
- (BOOL)drawCanUndo
{
    return _drawView.canUndo;
}
- (void)drawUndo
{
    [_drawView undo];
}

#pragma mark - 贴图功能
/** 创建贴图 */
- (void)createStickerImage:(UIImage *)image
{
    [_stickerView createImage:image];
}

#pragma mark - 文字功能
/** 创建文字 */
- (void)createStickerText:(NSString *)text
{
    if (text.length) {
        [_stickerView createText:text];
    }
}

#pragma mark - 懒加载
- (LFDrawView *)drawView
{
    if (_drawView == nil) {
        _drawView = [[LFDrawView alloc] init];
        _drawView.userInteractionEnabled = NO;
    }
    
    if (_drawView && _container) {
        [_drawView setFrame:_container.bounds];
    }
    
    return _drawView;
}

- (LFStickerView *)stickerView
{
    if (_stickerView == nil) {
        _stickerView = [[LFStickerView alloc] init];
//        _stickerView.userInteractionEnabled = NO;
    }
    
    if (_stickerView && _container) {
        [_stickerView setFrame:_container.bounds];
    }
    
    return _stickerView;
}

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone{
    LFPhotoEdit *photoEdit = [[[self class] allocWithZone:zone] init];
    /** 编辑图片 */
    [photoEdit setEditImage:self.editPreviewImage];
    photoEdit.drawView = [self.drawView copy];
    photoEdit.stickerView = [self.stickerView copy];
    
    return photoEdit;
}

@end
