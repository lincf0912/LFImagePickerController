//
//  LFAlbumTitleView.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2019/9/24.
//  Copyright © 2019 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LFAlbum.h"
#import "LFImagePickerPublicHeader.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LFAlbumTitleViewState) {
    LFAlbumTitleViewStateInactive,
    LFAlbumTitleViewStateActivity,
};

@interface LFAlbumTitleView : UIView

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController;
- (instancetype)initWithContentViewController:(UIViewController *)contentViewController index:(NSInteger)index;

@property (nonatomic, strong) NSArray <LFAlbum *>*albumArr;
@property (nonatomic, readonly) LFAlbum *selectedAlbum;

/** 自定义title */
@property (nonatomic, copy) NSString *title;
/** 选中图标 */
@property (nonatomic, copy) NSString *selectImageName;

/** 文字字体 boldSystemFontOfSize 18 */
@property(nonatomic, strong) UIFont *titleFont;
/** 文字颜色 灰色 */
@property(nonatomic, strong) UIColor *titleColor;
/** 当前序列 default -1 */
@property(nonatomic, assign, readonly) NSInteger index;
/** 点击背景隐藏 default YES */
@property(nonatomic, assign, getter=isTapBackgroundHidden) BOOL tapBackgroundHidden;
/** 状态 */
@property (nonatomic, assign) LFAlbumTitleViewState state;
/** 点击回调 */
@property (nonatomic, copy) void(^didSelected)(LFAlbum *album, NSInteger index);

@end

NS_ASSUME_NONNULL_END
