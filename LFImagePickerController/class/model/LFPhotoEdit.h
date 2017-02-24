//
//  LFPhotoEdit.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/23.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LFPhotoEdittingType) {
    /** 绘画 */
    LFPhotoEdittingType_draw = 0,
    /** 贴图 */
    LFPhotoEdittingType_sticker,
    /** 文本 */
    LFPhotoEdittingType_text,
    /** 模糊 */
    LFPhotoEdittingType_splash,
    /** 修剪 */
    LFPhotoEdittingType_crop,
};

@protocol LFPhotoEditDrawDelegate;

@interface LFPhotoEdit : NSObject

/** 编辑封面 */
@property (nonatomic, readonly) UIImage *editPosterImage;
/** 编辑图片 */
@property (nonatomic, readonly) UIImage *editPreviewImage;
/** 是否有效->有编辑过 */
@property (nonatomic, readonly) BOOL isWork;
/** 是否有改变编辑 */
@property (nonatomic, readonly) BOOL isChanged;

/** 控件Class */
+ (NSArray <Class>*)touchClass;

/** 初始化控件容器 */
- (instancetype)initWithContainer:(UIView *)container;
/** 设置控件容器 */
- (void)setContainer:(UIView *)container;
/** 清空容器控件 */
- (void)clearContainer;

/** 生成编辑图片 NO->编辑没有变动 YES->生成编辑图片 */
- (BOOL)mergedContainerLayer;
/** 回滚功能 */
- (void)rollback;

/** 代理 */
@property (nonatomic ,weak) id<LFPhotoEditDrawDelegate> delegate;


/** 启用绘画功能 */
@property (nonatomic, assign) BOOL drawEnable;
/** 是否可撤销 */
@property (nonatomic, readonly) BOOL drawCanUndo;
/** 撤销绘画 */
- (void)drawUndo;


@end

/** ====绘画代理==== */
@protocol LFPhotoEditDrawDelegate <NSObject>
/** 开始绘画 */
- (void)lf_photoEditDrawBegan:(LFPhotoEdit *)manager;
/** 结束绘画 */
- (void)lf_photoEditDrawEnded:(LFPhotoEdit *)manager;
@end
