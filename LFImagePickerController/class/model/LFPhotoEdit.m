//
//  LFPhotoEdit.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoEdit.h"
#import "LFDrawView.h"
#import "UIImage+LFCommon.h"
#import "UIView+LFCommon.h"

@interface LFPhotoEdit ()

/** 容器 */
@property (nonatomic, weak) UIView *container;

/** 绘画 */
@property (nonatomic, strong) LFDrawView *drawView;
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
    return @[[LFDrawView class]];
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
    
}

#pragma mark - 清空容器控件
- (void)clearContainer
{
    [_drawView removeFromSuperview];
    
    /** 关闭功能 */
    [self setDrawEnable:NO];
    
    /** 清除代理 */
    self.delegate = nil;
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
        } else if (self.isChanged) { /** 有改变编辑 */
            [self commit]; /** 提交功能 */
            [self setEditImage:[_container captureImage]];
            return YES;
        }
    }
    return NO;
}
/** 是否有效->有编辑过 */
- (BOOL)isWork
{
    return self.drawView.canUndo; /** 绘画没有可撤销->没有绘画 */
}
/** 是否有改变编辑 */
- (BOOL)isChanged
{
    return self.drawView.isChanged; /** 绘画发生改变 */
}

/** 提交 */
- (void)commit
{
    [self.drawView commit]; /** 提交绘画 */
}
/** 回滚 */
- (void)rollback
{
    [self.drawView rollback]; /** 回滚绘画 */
}

- (void)setDelegate:(id<LFPhotoEditDrawDelegate>)delegate
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

@end
