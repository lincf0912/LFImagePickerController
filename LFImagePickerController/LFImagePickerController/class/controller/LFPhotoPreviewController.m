//
//  LFPhotoPreviewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewController.h"
#import "LFImagePickerController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "LFPhotoPreviewCell.h"
#import "LFPhotoPreviewGifCell.h"
#import "LFPhotoPreviewLivePhotoCell.h"
#import "LFPhotoPreviewVideoCell.h"
#import "LFPreviewBar.h"
#import <PhotosUI/PhotosUI.h>

#import "LFAssetManager.h"
#import "UIImage+LFCommon.h"

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditingController.h"
#import "LFVideoEditingController.h"
#import "LFPhotoEditManager.h"
#import "LFVideoEditManager.h"
#endif

#import "LFGifPlayerManager.h"

CGFloat const cellMargin = 20.f;
CGFloat const livePhotoSignMargin = 10.f;
CGFloat const toolbarDefaultHeight = 44.f;
CGFloat const previewBarDefaultHeight = 64.f;

#ifdef LF_MEDIAEDIT
@interface LFPhotoPreviewController () <UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate,LFPhotoPreviewCellDelegate, LFPhotoEditingControllerDelegate, LFVideoEditingControllerDelegate>
#else
@interface LFPhotoPreviewController () <UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate,LFPhotoPreviewCellDelegate>
#endif
{
    UIView *_naviBar;
    UIView *_naviSubBar;
    UIButton *_backButton;
    UILabel *_titleLabel;
    UIButton *_selectButton;
    
    UIView *_toolBar;
    UIView *_toolSubBar;
    UIButton *_doneButton;
    
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    UIButton *_editButton;
    
    UIView *_livePhotoSignView;
    UIButton *_livePhotobadgeImageButton;
    
    UIView *_previewMainBar;
    LFPreviewBar *_previewBar;
}

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray <LFAsset *>*models;                  ///< All photo models / 所有图片模型数组
@property (nonatomic, assign) NSInteger currentIndex;           ///< Index of the photo user click / 用户点击的图片的索引

@property (nonatomic, assign) BOOL isHideMyNaviBar;

@property (nonatomic, assign) BOOL isPhotoPreview;
/** 手动滑动标记 */
@property (nonatomic, assign) BOOL isMTScroll;

/** 3DTouch预览状态 */
@property (nonatomic, assign) BOOL isPreviewing;
@property (nonatomic, weak) LFImagePickerController *previewNavi;

/** 临时编辑图片(仅用于在夸页面编辑时使用，目前已移除此需求) */
@property (nonatomic, strong) UIImage *tempEditImage;
@end

@implementation LFPhotoPreviewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isHiddenNavBar = YES;
        self.isHiddenStatusBar = YES;
    }
    return self;
}

- (instancetype)initWithModels:(NSArray <LFAsset *>*)models index:(NSInteger)index
{
    self = [self init];
    if (self) {
        if (models) {
            _models = [NSMutableArray arrayWithArray:models];
            _currentIndex = index;
        }
    }
    return self;
}
- (instancetype)initWithPhotos:(NSArray <LFAsset *>*)photos index:(NSInteger)index
{
    self = [self init];
    if (self) {
        if (photos) {
            _models = [photos mutableCopy];
            _currentIndex = index;
            _isPhotoPreview = YES;
        }
    }
    return self;
}

/** 3DTouch */
- (void)beginPreviewing:(UINavigationController *)navi
{
    _previewNavi = (LFImagePickerController *)navi;
    _isPreviewing = YES;
}
- (void)endPreviewing
{
    _previewNavi = nil;
    _isPreviewing = NO;
    if (_naviBar == nil) {
        [self configCustomNaviBar];
        [self configBottomToolBar];
        [self configPreviewBar];
        [self configLivePhotoSign];
        [self refreshNaviBarAndBottomBarState];
    }
}

- (LFImagePickerController *)navi
{
    return _isPreviewing ? _previewNavi : (LFImagePickerController *)self.navigationController;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configCollectionView];
    if (self.isPreviewing == NO) {
        [self configCustomNaviBar];
        [self configBottomToolBar];
        [self configPreviewBar];
        [self configLivePhotoSign];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_currentIndex) [_collectionView setContentOffset:CGPointMake(_collectionView.width * _currentIndex, 0) animated:NO];
    [self refreshNaviBarAndBottomBarState];
    
    if (self.isPreviewing == NO) {
        [[_collectionView visibleCells] makeObjectsPerformSelector:@selector(willDisplayCell)];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.isPreviewing == NO) {
        [[_collectionView visibleCells] makeObjectsPerformSelector:@selector(didEndDisplayCell)];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    /* 适配导航栏 */
    CGFloat naviBarHeight = 0, naviSubBarHeight = 0;
    naviBarHeight = naviSubBarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    if (@available(iOS 11.0, *)) {
        naviBarHeight += (self.view.safeAreaInsets.top > 0 ?: (CGRectGetWidth([UIScreen mainScreen].bounds) < CGRectGetHeight([UIScreen mainScreen].bounds) ? 20 : 0));
    }

    
    _naviBar.frame = CGRectMake(0, 0, self.view.width, naviBarHeight);
    CGRect naviSubBarRect = CGRectMake(0, naviBarHeight-naviSubBarHeight, self.view.width, naviSubBarHeight);
    if (@available(iOS 11.0, *)) {
        naviSubBarRect.origin.x += self.view.safeAreaInsets.left;
        naviSubBarRect.size.width -= self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
    }
    _naviSubBar.frame = naviSubBarRect;
    _backButton.height = CGRectGetHeight(_naviSubBar.frame);
    _selectButton.y = (CGRectGetHeight(_naviSubBar.frame)-CGRectGetHeight(_selectButton.frame))/2;
    _titleLabel.y = (CGRectGetHeight(_naviSubBar.frame)-CGRectGetHeight(_titleLabel.frame))/2;
    
    /* 适配标记图标 */
    _livePhotoSignView.x = CGRectGetMinX(_naviSubBar.frame) + livePhotoSignMargin;
    _livePhotoSignView.y = naviBarHeight + livePhotoSignMargin;
    
    /* 适配底部栏 */
    CGFloat toolbarHeight = toolbarDefaultHeight;
    if (@available(iOS 11.0, *)) {
        toolbarHeight += self.view.safeAreaInsets.bottom;
    }
    _toolBar.frame = CGRectMake(0, self.view.height - toolbarHeight, self.view.width, toolbarHeight);
    CGRect toolbarRect = _toolBar.bounds;
    if (@available(iOS 11.0, *)) {
        toolbarRect.origin.x += self.view.safeAreaInsets.left;
        toolbarRect.size.width -= self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
    }
    _toolSubBar.frame = toolbarRect;
    
    /* 适配预览栏 */
    _previewMainBar.frame = CGRectMake(0, _toolBar.y - previewBarDefaultHeight, self.view.width, previewBarDefaultHeight);;
    CGRect previewBarRect = _previewMainBar.bounds;
    if (@available(iOS 11.0, *)) {
        previewBarRect.origin.x += self.view.safeAreaInsets.left;
        previewBarRect.size.width -= self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
    }
    _previewBar.frame = previewBarRect;
    
    /* 适配宫格视图 */
    _collectionView.frame = CGRectMake(0, 0, self.view.width+ cellMargin, self.view.height);;
    _collectionView.contentSize = CGSizeMake(_models.count * (_collectionView.width), 0);
    /** 重新排版 */
    [_collectionView.collectionViewLayout invalidateLayout];
    if (_models.count) [_collectionView setContentOffset:CGPointMake((_collectionView.width) * _currentIndex, 0) animated:NO];
}

- (void)dealloc
{
    [LFGifPlayerManager free];
}

- (void)configCustomNaviBar {
    LFImagePickerController *imagePickerVc = [self navi];
    
    CGFloat naviBarHeight = 0, naviSubBarHeight = 0;
    naviBarHeight = naviSubBarHeight = CGRectGetHeight(self.navigationController.navigationBar.frame);
    if (@available(iOS 11.0, *)) {
        naviBarHeight += self.view.safeAreaInsets.top;
    }
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, naviBarHeight)];
    _naviBar.backgroundColor = imagePickerVc.previewNaviBgColor;
    
    _naviSubBar = [[UIView alloc] initWithFrame:CGRectMake(0, naviBarHeight-naviSubBarHeight, self.view.width, naviSubBarHeight)];
    [_naviBar addSubview:_naviSubBar];
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 0, 50, CGRectGetHeight(_naviSubBar.frame))];
    _backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    /** 判断是否预览模式 */
    if (imagePickerVc.isPreview) {
        /** 取消 */
        [_backButton setTitle:imagePickerVc.cancelBtnTitleStr forState:UIControlStateNormal];
        _backButton.titleLabel.font = [UIFont systemFontOfSize:15];
        CGFloat editCancelWidth = [imagePickerVc.cancelBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:_backButton.titleLabel.font} context:nil].size.width + 2;
        _backButton.width = editCancelWidth;
    } else {
        UIImage *image = bundleImageNamed(@"navigationbar_back_arrow");
        [_backButton setImage:image forState:UIControlStateNormal];
        _backButton.imageEdgeInsets = UIEdgeInsetsMake(0, image.size.width-50, 0, 0);
    }
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_naviSubBar addSubview:_backButton];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(_naviSubBar.frame) - 30 - 8, (CGRectGetHeight(_naviSubBar.frame)-30)/2, 30, 30)];
    _selectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_selectButton setImage:bundleImageNamed(imagePickerVc.photoDefImageName) forState:UIControlStateNormal];
    [_selectButton setImage:bundleImageNamed(imagePickerVc.photoSelImageName) forState:UIControlStateSelected];
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    [_naviSubBar addSubview:_selectButton];
    
    if (imagePickerVc.displayImageFilename) {        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:17];
        CGFloat height = [@"A" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(_naviSubBar.frame)) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:_titleLabel.font} context:nil].size.height;
        
        CGFloat titleMargin = MAX(_backButton.width, _selectButton.width) + 8;
        
        _titleLabel.frame = CGRectMake(titleMargin, (CGRectGetHeight(_naviSubBar.frame)-height)/2, CGRectGetWidth(_naviSubBar.frame) - titleMargin * 2, height);
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [_naviSubBar addSubview:_titleLabel];
    }
    
    [self.view addSubview:_naviBar];
}

- (void)configBottomToolBar {
    
    LFImagePickerController *imagePickerVc = [self navi];
    UIColor *toolbarBGColor = imagePickerVc.toolbarBgColor;
    UIColor *toolbarTitleColorNormal = imagePickerVc.toolbarTitleColorNormal;
    UIColor *toolbarTitleColorDisabled = imagePickerVc.toolbarTitleColorDisabled;
    UIFont *toolbarTitleFont = imagePickerVc.toolbarTitleFont;
    
    CGFloat toolbarHeight = toolbarDefaultHeight;
    if (@available(iOS 11.0, *)) {
        toolbarHeight += self.view.safeAreaInsets.bottom;
    }
    
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - toolbarHeight, self.view.width, toolbarHeight)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolBar.backgroundColor = toolbarBGColor;
    
    UIView *toolSubBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, toolbarDefaultHeight)];
    toolSubBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _toolSubBar = toolSubBar;
    
#ifdef LF_MEDIAEDIT
    if (imagePickerVc.allowEditing) {
        CGFloat editWidth = [imagePickerVc.editBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width + 2;
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editButton.frame = CGRectMake(10, 0, editWidth, CGRectGetHeight(_toolSubBar.frame));
        _editButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _editButton.titleLabel.font = toolbarTitleFont;
        [_editButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateNormal];
        [_editButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_editButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
    }
#endif
    
    if (imagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat width = fullImageWidth + 56;
#ifdef LF_MEDIAEDIT
        BOOL allowEditing = imagePickerVc.allowEditing;
#else
        BOOL allowEditing = NO;
#endif
        if (!allowEditing) { /** 非编辑模式 原图显示在左边 */
            _originalPhotoButton.frame = CGRectMake(0, 0, width, CGRectGetHeight(_toolSubBar.frame));
            _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        } else {
            _originalPhotoButton.frame = CGRectMake((CGRectGetWidth(_toolSubBar.frame)-width)/2, 0, width, CGRectGetHeight(_toolSubBar.frame));
            _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        }
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = toolbarTitleFont;
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateNormal];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginSelImageName) forState:UIControlStateSelected];
        
        _originalPhotoButton.selected = imagePickerVc.isSelectOriginalPhoto;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 42, 0, 80, CGRectGetHeight(_toolSubBar.frame));
        if (!allowEditing) { /** 非编辑模式 原图显示在左边 */
            _originalPhotoLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        } else {
            _originalPhotoLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
        }
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = toolbarTitleFont;
        _originalPhotoLabel.textColor = toolbarTitleColorNormal;
        _originalPhotoLabel.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addSubview:_originalPhotoLabel];
        if (_originalPhotoButton.selected) [self showPhotoBytes];
    }
    
    CGSize doneSize = [[imagePickerVc.doneBtnTitleStr stringByAppendingFormat:@"(%d)", (int)imagePickerVc.maxImagesCount] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size;
    doneSize.height = MIN(MAX(doneSize.height, CGRectGetHeight(_toolSubBar.frame)), 30);
    doneSize.width += 4;
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(CGRectGetWidth(_toolSubBar.frame) - doneSize.width - 12, (CGRectGetHeight(_toolSubBar.frame)-doneSize.height)/2, doneSize.width, doneSize.height);
    _doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _doneButton.titleLabel.font = toolbarTitleFont;
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
    _doneButton.layer.cornerRadius = CGRectGetHeight(_doneButton.frame)*0.2;
    _doneButton.layer.masksToBounds = YES;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    
    UIView *divide = [[UIView alloc] init];
    divide.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.1f];
    divide.frame = CGRectMake(0, 0, self.view.width, 1);
    divide.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    [toolSubBar addSubview:_editButton];
    [toolSubBar addSubview:_originalPhotoButton];
    [toolSubBar addSubview:_doneButton];
    [toolSubBar addSubview:divide];
    [_toolBar addSubview:toolSubBar];
    [self.view addSubview:_toolBar];
}

- (void)configPreviewBar {
    
    LFImagePickerController *imagePickerVc = [self navi];
    
    UIView *previewMainBar = [[UIView alloc] initWithFrame:CGRectMake(0, _toolBar.y - previewBarDefaultHeight, self.view.width, previewBarDefaultHeight)];
    previewMainBar.backgroundColor = imagePickerVc.toolbarBgColor;
    _previewMainBar = previewMainBar;
    
    _previewBar = [[LFPreviewBar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, previewBarDefaultHeight)];
    _previewBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _previewBar.backgroundColor = [UIColor clearColor];
    _previewBar.borderWidth = 2.f;
    _previewBar.borderColor = imagePickerVc.oKButtonTitleColorNormal;
    _previewBar.dataSource = [imagePickerVc.selectedModels copy];
    _previewBar.selectAsset = [self.models objectAtIndex:self.currentIndex];
    
    __weak typeof(self) weakSelf = self;
    _previewBar.didSelectItem = ^(LFAsset *asset) {
        NSInteger index = [weakSelf.models indexOfObject:asset];
        if (index != NSNotFound) {            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            weakSelf.isMTScroll = YES;
            [weakSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
        }
    };
    
    _previewBar.didMoveItem = ^(NSInteger sourceIndex, NSInteger destinationIndex) {
        if (weakSelf.alwaysShowPreviewBar) {
            //取出移动row数据
            LFAsset *asset = weakSelf.models[sourceIndex];
            //从数据源中移除该数据
            [weakSelf.models removeObject:asset];
            //将数据插入到数据源中的目标位置
            [weakSelf.models insertObject:asset atIndex:destinationIndex];
            
            /** 重新创建选择数组内容 */
            [imagePickerVc.selectedModels removeAllObjects];
            for (LFAsset *asset in weakSelf.models) {
                if (asset.isSelected) {
                    [imagePickerVc.selectedModels addObject:asset];
                }
            }
            
            NSInteger index = weakSelf.currentIndex;
            if (weakSelf.currentIndex == sourceIndex) {
                weakSelf.currentIndex = destinationIndex;
            } else if (sourceIndex > weakSelf.currentIndex && destinationIndex <= weakSelf.currentIndex) {
                weakSelf.currentIndex ++;
            } else if (sourceIndex < weakSelf.currentIndex && destinationIndex >= weakSelf.currentIndex) {
                weakSelf.currentIndex --;
            }
            [weakSelf.collectionView reloadData];
            if (index != weakSelf.currentIndex) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:weakSelf.currentIndex inSection:0];
                weakSelf.isMTScroll = YES;
                [weakSelf.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
            }
        } else {
            //取出移动row数据
            LFAsset *asset = imagePickerVc.selectedModels[sourceIndex];
            //从数据源中移除该数据
            [imagePickerVc.selectedModels removeObject:asset];
            //将数据插入到数据源中的目标位置
            [imagePickerVc.selectedModels insertObject:asset atIndex:destinationIndex];
        }
        
        [weakSelf refreshNaviBarAndBottomBarState];
    };
    [_previewMainBar addSubview:_previewBar];
    
    [self.view addSubview:_previewMainBar];
}

- (void)configLivePhotoSign
{
    _livePhotoSignView = [[UIView alloc] initWithFrame:CGRectMake(livePhotoSignMargin, livePhotoSignMargin + CGRectGetHeight(_naviBar.frame), 30, 30)];
    _livePhotoSignView.backgroundColor = [UIColor colorWithWhite:.8f alpha:.8f];
//    _livePhotoSignView.alpha = 0.8f;
    _livePhotoSignView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _livePhotoSignView.layer.masksToBounds = YES;
    _livePhotoSignView.layer.cornerRadius = 30 * 0.2f;
    [self.view addSubview:_livePhotoSignView];
    
    
    UIImageView *badgeImageView = [[UIImageView alloc] initWithFrame:_livePhotoSignView.bounds];
    badgeImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [badgeImageView setImage:[PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent]];
    CALayer *maskLayer = badgeImageView.layer;
    
    
    UIButton *badgeImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    badgeImageButton.frame = _livePhotoSignView.bounds;
    badgeImageButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    badgeImageButton.layer.masksToBounds = YES;
    badgeImageButton.layer.mask = maskLayer;
    
    UIImage *badgeImage = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
    [badgeImageButton setImage:badgeImage forState:UIControlStateNormal];
    [badgeImageButton setImage:badgeImage forState:UIControlStateHighlighted];
    [badgeImageButton setImage:badgeImage forState:UIControlStateSelected | UIControlStateHighlighted];
    [badgeImageButton addTarget:self action:@selector(livePhotoSignButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [_livePhotoSignView addSubview:badgeImageButton];
    _livePhotobadgeImageButton = badgeImageButton;
    
    _livePhotoSignView.alpha = 0.f;
    
    [self selectedLivePhotobadgeImageButton:YES];
}

- (void)configCollectionView {
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
//    layout.itemSize = CGSizeMake(self.view.width, self.view.height);
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = cellMargin;
    layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, cellMargin);
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.width + cellMargin, self.view.height) collectionViewLayout:layout];
//    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(_models.count * (_collectionView.width), 0);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[LFPhotoPreviewCell class] forCellWithReuseIdentifier:@"LFPhotoPreviewCell"];
    [_collectionView registerClass:[LFPhotoPreviewGifCell class] forCellWithReuseIdentifier:@"LFPhotoPreviewGifCell"];
    [_collectionView registerClass:[LFPhotoPreviewLivePhotoCell class] forCellWithReuseIdentifier:@"LFPhotoPreviewLivePhotoCell"];
    [_collectionView registerClass:[LFPhotoPreviewVideoCell class] forCellWithReuseIdentifier:@"LFPhotoPreviewVideoCell"];
}

#pragma mark - Click Event

- (void)select:(UIButton *)selectButton {
    LFImagePickerController *imagePickerVc = [self navi];
    LFAsset *model = _models[_currentIndex];
    if (!selectButton.isSelected) {
        // 1. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
        if (imagePickerVc.selectedModels.count >= imagePickerVc.maxImagesCount) {
            NSString *title = [NSString stringWithFormat:@"你最多只能选择%zd张照片", imagePickerVc.maxImagesCount];
            [imagePickerVc showAlertWithTitle:title];
            return;
            // 2. if not over the maxImagesCount / 如果没有超过最大个数限制
        } else {
            /** 检测是否超过视频最大时长 */
            if (model.type == LFAssetMediaTypeVideo && model.duration > imagePickerVc.maxVideoDuration) {
                [imagePickerVc showAlertWithTitle:[NSString stringWithFormat:@"不能选择超过%d分钟的视频", (int)imagePickerVc.maxVideoDuration/60]];
                return;
            }
            if (self.alwaysShowPreviewBar) {
                NSInteger index = 0;
                for (LFAsset *asset in self.models) {
                    if (asset.isSelected) {
                        index ++;
                    }
                    if (asset == model) {
                        break;
                    }
                }
                [imagePickerVc.selectedModels insertObject:model atIndex:index];
            } else {
                [imagePickerVc.selectedModels addObject:model];
            }
        }
    } else {
        NSArray *selectedModels = [NSArray arrayWithArray:imagePickerVc.selectedModels];
        for (NSInteger i = 0; i < selectedModels.count; i++) {
            LFAsset *model_item = selectedModels[i];
            if (!_isPhotoPreview) {
                if ([[[LFAssetManager manager] getAssetIdentifier:model.asset] isEqualToString:[[LFAssetManager manager] getAssetIdentifier:model_item.asset]]) {
                    [imagePickerVc.selectedModels removeObjectAtIndex:i];
                    break;
                }
            } else { /** UIImage模式 */
                if ([model_item isEqual:model]) {
                    [imagePickerVc.selectedModels removeObjectAtIndex:i];
                    break;
                }
            }
        }
    }
    model.isSelected = !selectButton.isSelected;
    
    /** 非总是显示模式，添加对象 */
    if (!self.alwaysShowPreviewBar) {
        if (model.isSelected) {
            [_previewBar addAssetInDataSource:model];
        } else {
            [_previewBar removeAssetInDataSource:model];
        }
    }
    
    [self refreshNaviBarAndBottomBarState];
    if (model.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:OscillatoryAnimationToBigger];
    }
}

- (void)backButtonClick {
    LFImagePickerController *imagePickerVc = [self navi];
    /** 判断是否预览模式 */
    if (imagePickerVc.isPreview) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
    if (self.backButtonClickBlock) {
        self.backButtonClickBlock();
    }
}

- (void)doneButtonClick {
    LFImagePickerController *imagePickerVc = [self navi];
    
    // 如果没有选中过照片 点击确定时选中当前预览的照片
    if (imagePickerVc.autoSelectCurrentImage && imagePickerVc.selectedModels.count == 0 && imagePickerVc.minImagesCount <= 0) {
        LFAsset *model = _models[_currentIndex];
        [imagePickerVc.selectedModels addObject:model];
    }
    
    if (imagePickerVc.minImagesCount && imagePickerVc.selectedModels.count < imagePickerVc.minImagesCount) {
        NSString *title = [NSString stringWithFormat:@"请至少选择%zd张照片", imagePickerVc.minImagesCount];
        [imagePickerVc showAlertWithTitle:title];
        return;
    }

    if (self.doneButtonClickBlock) {
        self.doneButtonClickBlock();
    }
}

#ifdef LF_MEDIAEDIT
- (void)editButtonClick {
    if (self.models.count > self.currentIndex) {
        LFImagePickerController *imagePickerVc = [self navi];
        /** 获取缓存编辑对象 */
        LFAsset *model = [self.models objectAtIndex:self.currentIndex];
        
        LFBaseEditingController *editingVC = nil;
        
        if (model.type == LFAssetMediaTypePhoto) {
            LFPhotoEditingController *photoEditingVC = [[LFPhotoEditingController alloc] init];
            editingVC = photoEditingVC;
            
            LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
            if (photoEdit) {
                photoEditingVC.photoEdit = photoEdit;
            } else {
                /** 当前页面只显示一张图片 */
                LFPhotoPreviewCell *cell = [_collectionView visibleCells].firstObject;
                /** 当前显示的图片 */
                photoEditingVC.editImage = cell.previewImage;
            }
            photoEditingVC.delegate = self;
            if (imagePickerVc.photoEditLabrary) {
                imagePickerVc.photoEditLabrary(photoEditingVC);
            }
        } else if (model.type == LFAssetMediaTypeVideo) {
            LFVideoEditingController *videoEditingVC = [[LFVideoEditingController alloc] init];
            editingVC = videoEditingVC;
            videoEditingVC.minClippingDuration = 3.f;
            
            LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:model];
            if (videoEdit) {
                videoEditingVC.videoEdit = videoEdit;
            } else {
                LFPhotoPreviewVideoCell *cell = [_collectionView visibleCells].firstObject;
                /** 当前显示的图片 */
                [videoEditingVC setVideoAsset:cell.asset placeholderImage:cell.previewImage];
            }
            videoEditingVC.delegate = self;
            if (imagePickerVc.videoEditLabrary) {
                imagePickerVc.videoEditLabrary(videoEditingVC);
            }
        }
        
        if (editingVC) {
            [imagePickerVc pushViewController:editingVC animated:NO];
        }
    }
}
#endif

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    LFImagePickerController *imagePickerVc = [self navi];
    imagePickerVc.isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_originalPhotoButton.selected) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            if (imagePickerVc.selectedModels.count < imagePickerVc.maxImagesCount) {
                [self select:_selectButton];
            }
        }
    } else {
        _originalPhotoLabel.text = nil;
    }
}

- (void)livePhotoSignButtonClick:(UIButton *)button
{
    [self selectedLivePhotobadgeImageButton:!button.isSelected];
    LFAsset *model = _models[_currentIndex];
    model.closeLivePhoto = !model.closeLivePhoto;
    
    LFPhotoPreviewCell *cell = (LFPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_currentIndex inSection:0]];
    
    if (model.closeLivePhoto) {
        [cell didEndDisplayCell];
    } else {
        [cell willDisplayCell];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    _isMTScroll = YES;
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[LFPhotoPreviewVideoCell class]]) {
            [(LFPhotoPreviewVideoCell *)obj didPauseCell];
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (_isMTScroll) {        
        CGFloat offSetWidth = scrollView.contentOffset.x;
        offSetWidth = offSetWidth +  (_collectionView.width/2);
        
        NSInteger currentIndex = offSetWidth / (_collectionView.width);
        
        if (currentIndex < _models.count && _currentIndex != currentIndex) {
            _currentIndex = currentIndex;
            [self refreshNaviBarAndBottomBarState];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _isMTScroll = NO;
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LFPhotoPreviewCell *cell = nil;
    LFAsset *model = _models[indexPath.row];
    LFImagePickerController *imagePickerVc = [self navi];
    if (model.type == LFAssetMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFPhotoPreviewVideoCell" forIndexPath:indexPath];
    } else {
        if (imagePickerVc.allowPickingGif && model.subType == LFAssetSubMediaTypeGIF) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFPhotoPreviewGifCell" forIndexPath:indexPath];
        } else if (imagePickerVc.allowPickingLivePhoto && model.subType == LFAssetSubMediaTypeLivePhoto) {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFPhotoPreviewLivePhotoCell" forIndexPath:indexPath];
        } else {
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFPhotoPreviewCell" forIndexPath:indexPath];
        }
    }
    cell.delegate = self;
    /** 设置图片，与编辑图片的必须一致，因为获取图片选择快速优化方案，图片大小会有小许偏差 */
    if (self.tempEditImage) {
        cell.previewImage = self.tempEditImage;
        self.tempEditImage = nil;
    }
    cell.model = model;
    
    /** 视频自动播放 */
    if (self.isPreviewing && model.type == LFAssetMediaTypeVideo) {
        [(LFPhotoPreviewVideoCell *)cell didPlayCell];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:[LFPhotoPreviewVideoCell class]]) {
        [(LFPhotoPreviewVideoCell *)cell didEndDisplayCell];
    }
}

#pragma mark -  UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.view.width, self.view.height);
}

#pragma mark - LFPhotoPreviewCellDelegate
- (void)lf_photoPreviewCellSingleTapHandler:(LFPhotoPreviewCell *)cell
{
    if (cell.model.type == LFAssetMediaTypeVideo) {
        if (((LFPhotoPreviewVideoCell *)cell).isPlaying && self.isHideMyNaviBar) {
            return;
        } else if (!((LFPhotoPreviewVideoCell *)cell).isPlaying && !self.isHideMyNaviBar) {
            return;
        }
    }
    LFImagePickerController *imagePickerVc = [self navi];
    // show or hide naviBar / 显示或隐藏导航栏
    self.isHideMyNaviBar = !self.isHideMyNaviBar;
    CGFloat alpha = self.isHideMyNaviBar ? 0.f : 1.f;
    [UIView animateWithDuration:0.25f animations:^{
        _naviBar.alpha = alpha;
        _toolBar.alpha = alpha;
        /** 非总是显示模式，并且 预览栏数量为0时，已经是被隐藏，不能显示, 取反操作 */
        if (!(!self.alwaysShowPreviewBar && _previewBar.dataSource.count == 0)) {
            _previewMainBar.alpha = alpha;
        }
        
        /** live photo 标记 */
        if (imagePickerVc.allowPickingLivePhoto && cell.model.subType == LFAssetSubMediaTypeLivePhoto) {
            _livePhotoSignView.alpha = alpha;
        }
    }];
}

#ifdef LF_MEDIAEDIT
#pragma mark - LFPhotoEditingControllerDelegate
- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEditingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit
{
    if (photoEdit == nil && _collectionView == nil) { /** 没有编辑 并且 UI未初始化 */
        self.tempEditImage = photoEditingVC.editImage;
    }
    
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEditingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit
{
    if (self.models.count > self.currentIndex) {
        LFAsset *model = [self.models objectAtIndex:self.currentIndex];
        /** 缓存对象 */
        [[LFPhotoEditManager manager] setPhotoEdit:photoEdit forAsset:model];
        
        /** 当前页面只显示一张图片 */
        LFPhotoPreviewCell *cell = [_collectionView visibleCells].firstObject;
        
        if (photoEdit) { /** 编辑存在 */
            if (_collectionView) {
                cell.previewImage = photoEdit.editPreviewImage;
            }
        } else { /** 编辑不存在 */
            if (_collectionView) { /** 不存在编辑不做reloadData操作，避免重新获取图片时会先获取模糊图片再到高清图片，可能出现闪烁的现象 */
                /** 还原编辑图片 */
                cell.previewImage = photoEditingVC.editImage;
            } else { /** UI未初始化，记录当前编辑图片，初始化后设置 */
                self.tempEditImage = photoEditingVC.editImage;
            }
        }
        
        /** 默认选中编辑后的图片 */
        if (!_selectButton.isSelected) {
            [self select:_selectButton];
        }
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}

#pragma mark - LFVideoEditingControllerDelegate
- (void)lf_VideoEditingController:(LFVideoEditingController *)videoEditingVC didCancelPhotoEdit:(LFVideoEdit *)videoEdit
{
    [self.navigationController popViewControllerAnimated:NO];
    
}
- (void)lf_VideoEditingController:(LFVideoEditingController *)videoEditingVC didFinishPhotoEdit:(LFVideoEdit *)videoEdit
{
    if (self.models.count > self.currentIndex) {
        LFAsset *model = [self.models objectAtIndex:self.currentIndex];
        /** 缓存对象 */
        [[LFVideoEditManager manager] setVideoEdit:videoEdit forAsset:model];
        LFPhotoPreviewVideoCell *cell = [_collectionView visibleCells].firstObject;
        if (videoEdit.editPreviewImage) { /** 编辑存在 */
            [cell changeVideoPlayer:[AVAsset assetWithURL:videoEdit.editFinalURL] image:videoEdit.editPreviewImage];
        } else {
            [cell changeVideoPlayer:videoEditingVC.asset image:videoEditingVC.placeholderImage];
        }
        
        /** 默认选中编辑后的视频 */
        if (!_selectButton.isSelected) {
            [self select:_selectButton];
        }
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}
#endif

#pragma mark - Private Method

- (void)refreshNaviBarAndBottomBarState {
    LFImagePickerController *imagePickerVc = [self navi];
    LFAsset *model = _models[_currentIndex];
    _selectButton.selected = model.isSelected;
    if (_selectButton.selected) {
        NSString *text = [NSString stringWithFormat:@"%zd", [imagePickerVc.selectedModels indexOfObject:model]+1];
        UIImage *image = [UIImage lf_mergeImage:bundleImageNamed(imagePickerVc.photoNumberIconImageName) text:text];
        [_selectButton setImage:image forState:UIControlStateSelected];
    }
    
    _doneButton.enabled = !self.alwaysShowPreviewBar || imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    
    _titleLabel.text = [model.name stringByDeletingPathExtension];
    
    if (imagePickerVc.selectedModels.count) {
        [_doneButton setTitle:[NSString stringWithFormat:@"%@(%zd)",imagePickerVc.doneBtnTitleStr ,imagePickerVc.selectedModels.count] forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    }
    
    _originalPhotoButton.hidden = model.type == LFAssetMediaTypeVideo;
    
    _originalPhotoLabel.hidden = !(_originalPhotoButton.selected && imagePickerVc.selectedModels.count > 0);
    if (_originalPhotoButton.selected) [self showPhotoBytes];
    
    /** 关闭编辑 已选数量达到最大限度 && 非选中图片  */
    _editButton.enabled = (imagePickerVc.selectedModels.count != imagePickerVc.maxImagesCount || model.isSelected);
    
    /** 预览栏动画 */
    if (!self.alwaysShowPreviewBar) {
        if (imagePickerVc.selectedModels.count) {
            [UIView animateWithDuration:0.25f animations:^{
                _previewMainBar.alpha = 1.f;
            }];
        } else {
            [UIView animateWithDuration:0.25f animations:^{
                _previewMainBar.alpha = 0.f;
            }];
        }
    }
    /** 预览栏选中与刷新 */
    _previewBar.selectAsset = model;
    
    /** live photo 标记 */
    if (imagePickerVc.allowPickingLivePhoto && model.subType == LFAssetSubMediaTypeLivePhoto) {
        [self selectedLivePhotobadgeImageButton:!model.closeLivePhoto];
        if (self.isHideMyNaviBar) return;
        [UIView animateWithDuration:0.25f animations:^{
            _livePhotoSignView.alpha = 1.f;
        }];
    } else {
        [UIView animateWithDuration:0.25f animations:^{
            _livePhotoSignView.alpha = 0.f;
        }];
    }
}

- (void)showPhotoBytes {
    if (/* DISABLES CODE */ (1)==0) {
        [[LFAssetManager manager] getPhotosBytesWithArray:@[_models[_currentIndex]] completion:^(NSString *totalBytes) {
            _originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
        }];
    }
}

- (void)selectedLivePhotobadgeImageButton:(BOOL)isSelected
{
    _livePhotobadgeImageButton.selected = isSelected;
    if (isSelected) {
        _livePhotobadgeImageButton.backgroundColor = [UIColor yellowColor];
    } else {
        _livePhotobadgeImageButton.backgroundColor = [UIColor whiteColor];
    }
}
@end
