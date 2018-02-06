//
//  LFPreviewBar.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFAsset;

@interface LFPreviewBar : UIView

@property (nonatomic, strong) NSArray <LFAsset *>*dataSource;
/** 选择数据源 */
@property (nonatomic, strong) NSMutableArray <LFAsset *>*selectedDataSource;

/** 显示与刷新游标 */
@property (nonatomic, strong) LFAsset *selectAsset;

/** 选择框大小 2.f */
@property (nonatomic, assign) CGFloat borderWidth;
/** 选择框颜色 blackColor */
@property (nonatomic, strong) UIColor *borderColor;

/** 添加数据源 */
- (void)addAssetInDataSource:(LFAsset *)asset;
/** 删除数据源 */
- (void)removeAssetInDataSource:(LFAsset *)asset;

@property (nonatomic, copy) void(^didSelectItem)(LFAsset *asset);
@property (nonatomic, copy) void(^didMoveItem)(LFAsset *asset, NSInteger sourceIndex, NSInteger destinationIndex);

@end
