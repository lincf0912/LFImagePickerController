//
//  LFPreviewBar.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPreviewBar.h"
#import "LFPreviewBarCell.h"

#import "LFAsset.h"

@interface LFPreviewBar () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray <LFAsset *>*myDataSource;
@end

@implementation LFPreviewBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    _borderWidth = 2.f;
    _borderColor = [UIColor blackColor];
    
    CGFloat margin = 5.f;
    CGFloat itemH = CGRectGetHeight(self.bounds) - margin * 2;
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(itemH, itemH);
    layout.sectionInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    layout.minimumLineSpacing = margin;
    layout.minimumInteritemSpacing = 0;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    [collectionView registerClass:[LFPreviewBarCell class] forCellWithReuseIdentifier:[LFPreviewBarCell identifier]];
}

- (void)setDataSource:(NSArray<LFAsset *> *)dataSource
{
    if (dataSource) {
        self.myDataSource = [NSMutableArray arrayWithArray:dataSource];
    } else {
        self.myDataSource = nil;
    }
}

- (NSArray<LFAsset *> *)dataSource{
    return [self.myDataSource copy];
}

/** 添加数据源 */
- (void)addAssetInDataSource:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        [weakSelf.myDataSource addObject:asset];
        [weakSelf.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:weakSelf.myDataSource.count-1 inSection:0]]];
        
    } completion:nil];
}
/** 删除数据源 */
- (void)removeAssetInDataSource:(LFAsset *)asset
{
    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        NSInteger index = [weakSelf.myDataSource indexOfObject:asset];
        [weakSelf.myDataSource removeObject:asset];
        if (index != NSNotFound) {
            [weakSelf.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]];
        }
        
    } completion:nil];
}

- (void)setSelectAsset:(LFAsset *)selectAsset
{
    NSMutableArray *indexPaths = [@[] mutableCopy];

    if (_selectAsset) {
        NSInteger index = [self.myDataSource indexOfObject:_selectAsset];
        if (index != NSNotFound) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [indexPaths addObject:indexPath];
        }
    }
    
    if (_selectAsset != selectAsset) {
        /** 刷新+滚动 */
        _selectAsset = selectAsset;
        
        if (_selectAsset) {
            NSInteger preIndex = [self.myDataSource indexOfObject:_selectAsset];
            if (preIndex != NSNotFound) {
                NSIndexPath *preIndexPath = [NSIndexPath indexPathForRow:preIndex inSection:0];
                [indexPaths addObject:preIndexPath];
            }
        }
    }
    
    if (indexPaths.count) {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
        } completion:^(BOOL finished) {
            [self.collectionView scrollToItemAtIndexPath:indexPaths.lastObject atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        }];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.myDataSource.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = [LFPreviewBarCell identifier];
    LFPreviewBarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    LFAsset *asset = self.myDataSource[indexPath.row];
    
    cell.asset = asset;
    
    if (asset == self.selectAsset) {
        cell.layer.borderColor = self.borderColor.CGColor;
        cell.layer.borderWidth = self.borderWidth;
    } else {
        cell.layer.borderWidth = 0.f;
    }
    
    return cell;
}

#pragma mark -  UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    LFAsset *asset = self.myDataSource[indexPath.row];
    if (self.didSelectItem) {
        self.didSelectItem(asset);
    }
    self.selectAsset = asset;
}

@end
