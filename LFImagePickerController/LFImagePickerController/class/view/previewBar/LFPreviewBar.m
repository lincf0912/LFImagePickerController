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

/**之前选中cell的NSIndexPath*/
@property (nonatomic, strong) NSIndexPath *oldIndexPath;
/**单元格的截图*/
@property (nonatomic, weak) UIView *snapshotView;
/**之前选中cell的NSIndexPath*/
@property (nonatomic, strong) NSIndexPath *moveIndexPath;
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
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.delegate = self;
    collectionView.dataSource = self;
    collectionView.backgroundColor = [UIColor clearColor];
    [self addSubview:collectionView];
    self.collectionView = collectionView;
    
    [collectionView registerClass:[LFPreviewBarCell class] forCellWithReuseIdentifier:[LFPreviewBarCell identifier]];
    
    // 添加长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlelongGesture:)];
    [collectionView addGestureRecognizer:longPress];
}

#pragma mark - 长按手势
- (void)handlelongGesture:(UILongPressGestureRecognizer *)longPress
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        [self action:longPress];
    } else {
        [self iOS9_Action:longPress];
    }
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

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 返回YES允许row移动
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    //取出移动row数据
    LFAsset *asset = self.myDataSource[sourceIndexPath.row];
    //从数据源中移除该数据
    [self.myDataSource removeObject:asset];
    //将数据插入到数据源中的目标位置
    [self.myDataSource insertObject:asset atIndex:destinationIndexPath.row];
    
    if (self.didMoveItem) {
        self.didMoveItem(sourceIndexPath.row, destinationIndexPath.row);
    }
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

#pragma mark - iOS9 之后的方法
- (void)iOS9_Action:(UILongPressGestureRecognizer *)longPress
{
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        { //手势开始
            //判断手势落点位置是否在row上
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            if (indexPath == nil) {
                break;
            }
            
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            [self bringSubviewToFront:cell];
            //iOS9方法 移动cell
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            [self starShake:self.snapshotView = cell];
        }
            break;
        case UIGestureRecognizerStateChanged:
        { // 手势改变
            // iOS9方法 移动过程中随时更新cell位置
            [self.collectionView updateInteractiveMovementTargetPosition:[longPress locationInView:self.collectionView]];
        }
            break;
        case UIGestureRecognizerStateEnded:
        { // 手势结束
            // iOS9方法 移动结束后关闭cell移动
            [self stopShake:self.snapshotView];
            self.snapshotView = nil;
            [self.collectionView endInteractiveMovement];
        }
            break;
        default: //手势其他状态
        {
            [self stopShake:self.snapshotView];
            self.snapshotView = nil;
            [self.collectionView cancelInteractiveMovement];
        }
            break;
    }
}

#pragma mark - iOS9 之前的方法
- (void)action:(UILongPressGestureRecognizer *)longPress
{
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        { // 手势开始
            //判断手势落点位置是否在row上
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
            self.oldIndexPath = indexPath;
            if (indexPath == nil) {
                break;
            }
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
            // 使用系统的截图功能,得到cell的截图视图
            UIView *snapshotView = [cell snapshotViewAfterScreenUpdates:NO];
            snapshotView.frame = cell.frame;
            [self addSubview:self.snapshotView = snapshotView];
            // 截图后隐藏当前cell
            cell.hidden = YES;
            [self starShake:snapshotView];
            
            CGPoint currentPoint = [longPress locationInView:self.collectionView];
            [UIView animateWithDuration:0.25 animations:^{
                snapshotView.transform = CGAffineTransformMakeScale(1.05, 1.05);
                snapshotView.center = currentPoint;
            }];
        }
            break;
        case UIGestureRecognizerStateChanged:
        { // 手势改变
            //当前手指位置 截图视图位置随着手指移动而移动
            CGPoint currentPoint = [longPress locationInView:self.collectionView];
            self.snapshotView.center = currentPoint;
            // 计算截图视图和哪个可见cell相交
            for (UICollectionViewCell *cell in self.collectionView.visibleCells) {
                // 当前隐藏的cell就不需要交换了,直接continue
                if ([self.collectionView indexPathForCell:cell] == self.oldIndexPath) {
                    continue;
                }
                // 计算中心距
                CGFloat space = sqrtf(pow(self.snapshotView.center.x - cell.center.x, 2) + powf(self.snapshotView.center.y - cell.center.y, 2));
                // 如果相交一半就移动
                if (space <= self.snapshotView.bounds.size.width / 2) {
                    self.moveIndexPath = [self.collectionView indexPathForCell:cell];
                    //移动 会调用willMoveToIndexPath方法更新数据源
                    [self.collectionView moveItemAtIndexPath:self.oldIndexPath toIndexPath:self.moveIndexPath];
                    //设置移动后的起始indexPath
                    self.oldIndexPath = self.moveIndexPath;
                    break;
                }
            }
        }
            break;
        default:
        { // 手势结束和其他状态
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:self.oldIndexPath];
            // 结束动画过程中停止交互,防止出问题
            self.collectionView.userInteractionEnabled = NO;
            [self stopShake:self.snapshotView];
            // 给截图视图一个动画移动到隐藏cell的新位置
            [UIView animateWithDuration:0.25 animations:^{
                self.snapshotView.center = cell.center;
                self.snapshotView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            } completion:^(BOOL finished) {
                // 移除截图视图,显示隐藏的cell并开始交互
                [self.snapshotView removeFromSuperview];
                self.oldIndexPath = nil;
                self.moveIndexPath = nil;
                cell.hidden = NO;
                self.collectionView.userInteractionEnabled = YES;
            }];
        }
            break;
    }
}

#pragma mark - private
- (void)starShake:(UIView *)view{
    
    CAKeyframeAnimation * keyAnimaion = [CAKeyframeAnimation animation];
    keyAnimaion.keyPath = @"transform.rotation";
    keyAnimaion.values = @[@(-3 / 180.0 * M_PI),@(3 /180.0 * M_PI),@(-3/ 180.0 * M_PI)];//度数转弧度
    keyAnimaion.removedOnCompletion = NO;
    keyAnimaion.fillMode = kCAFillModeForwards;
    keyAnimaion.duration = 0.25;
    keyAnimaion.repeatCount = MAXFLOAT;
    [view.layer addAnimation:keyAnimaion forKey:@"cellShake"];
}
- (void)stopShake:(UIView *)view{
    [view.layer removeAnimationForKey:@"cellShake"];
}


@end
