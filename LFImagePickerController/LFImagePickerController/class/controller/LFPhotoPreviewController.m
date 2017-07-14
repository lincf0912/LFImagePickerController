//
//  LFPhotoPreviewController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewController.h"
#import "LFImagePickerController.h"
#import "LFPhotoEditingController.h"
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
#import "LFPhotoEditManager.h"
#import "LFGifPlayerManager.h"

CGFloat const cellMargin = 20.f;
CGFloat const livePhotoSignMargin = 10.f;

@interface LFPhotoPreviewController () <UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate,LFPhotoPreviewCellDelegate, LFPhotoEditingControllerDelegate>
{
    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    UIButton *_editButton;
    
    UIView *_livePhotoSignView;
    UIButton *_livePhotobadgeImageButton;
    
    LFPreviewBar *_previewBar;
}

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray <LFAsset *>*models;                  ///< All photo models / 所有图片模型数组
@property (nonatomic, assign) NSInteger currentIndex;           ///< Index of the photo user click / 用户点击的图片的索引

@property (nonatomic, assign) BOOL isHideMyNaviBar;

@property (nonatomic, assign) BOOL isPhotoPreview;
/** 手动滑动标记 */
@property (nonatomic, assign) BOOL isMTScroll;

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

- (instancetype)initWithModels:(NSArray <LFAsset *>*)models index:(NSInteger)index excludeVideo:(BOOL)excludeVideo
{
    self = [self init];
    if (self) {
        if (models) {
            _models = [NSMutableArray arrayWithArray:models];
            _currentIndex = index;
            if (excludeVideo) {
                NSMutableArray *models = [_models mutableCopy];
                /** 移除视频对象 */
                for (NSInteger i = 0; i<models.count; i++) {
                    LFAsset *model = models[i];
                    if (model.type == LFAssetMediaTypeVideo) {
                        [models removeObjectAtIndex:i];
                        if (index > i) {
                            index--;
                        }
                        i--;
                    }
                }
                _currentIndex = index;
                _models = models;
            }
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

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    [self configPreviewBar];
    [self configLivePhotoSign];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_currentIndex) [_collectionView setContentOffset:CGPointMake(_collectionView.width * _currentIndex, 0) animated:NO];
    [self refreshNaviBarAndBottomBarState];
    
    [[_collectionView visibleCells] makeObjectsPerformSelector:@selector(willDisplayCell)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[_collectionView visibleCells] makeObjectsPerformSelector:@selector(didEndDisplayCell)];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _naviBar.height = [self navigationHeight];
    _livePhotoSignView.y = [self navigationHeight] + livePhotoSignMargin;
    /** 重新排版 */
    [_collectionView.collectionViewLayout invalidateLayout];
    _collectionView.frame = CGRectMake(0, 0, self.view.width + cellMargin, self.view.height);
    _collectionView.contentSize = CGSizeMake(_models.count * (_collectionView.width), 0);
    if (_currentIndex) [_collectionView setContentOffset:CGPointMake((_collectionView.width) * _currentIndex, 0) animated:NO];
}

- (void)dealloc
{
    [LFGifPlayerManager free];
}

- (void)configCustomNaviBar {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat naviBarHeight = [self navigationHeight];
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, naviBarHeight)];
    _naviBar.backgroundColor = imagePickerVc.previewNaviBgColor;
    _naviBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _backButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 0, 50, naviBarHeight)];
    _backButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    /** 判断是否预览模式 */
    if (imagePickerVc.isPreview) {
        /** 取消 */
        [_backButton setTitle:imagePickerVc.cancelBtnTitleStr forState:UIControlStateNormal];
        _backButton.titleLabel.font = [UIFont systemFontOfSize:15];
    } else {
        UIImage *image = bundleImageNamed(@"navigationbar_back_arrow");
        [_backButton setImage:image forState:UIControlStateNormal];
        _backButton.imageEdgeInsets = UIEdgeInsetsMake(0, image.size.width-50, 0, 0);
    }
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width - 30 - 8, (naviBarHeight-30)/2, 30, 30)];
    _selectButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_selectButton setImage:bundleImageNamed(imagePickerVc.photoDefImageName) forState:UIControlStateNormal];
    [_selectButton setImage:bundleImageNamed(imagePickerVc.photoSelImageName) forState:UIControlStateSelected];
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    [_naviBar addSubview:_selectButton];
    
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];
}

- (void)configBottomToolBar {
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    UIColor *toolbarBGColor = imagePickerVc.toolbarBgColor;
    UIColor *toolbarTitleColorNormal = imagePickerVc.toolbarTitleColorNormal;
    UIColor *toolbarTitleColorDisabled = imagePickerVc.toolbarTitleColorDisabled;
    UIFont *toolbarTitleFont = imagePickerVc.toolbarTitleFont;
    
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.height - 44, self.view.width, 44)];
    _toolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _toolBar.backgroundColor = toolbarBGColor;
    
    
    if (imagePickerVc.allowEditting) {
        CGFloat editWidth = [imagePickerVc.editBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width + 2;
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editButton.frame = CGRectMake(10, 0, editWidth, 44);
        _editButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _editButton.titleLabel.font = toolbarTitleFont;
        [_editButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateNormal];
        [_editButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_editButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
    }
    
    if (imagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat width = fullImageWidth + 56;
        if (!imagePickerVc.allowEditting) { /** 非编辑模式 原图显示在左边 */
            _originalPhotoButton.frame = CGRectMake(0, 0, width, 44);
            _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        } else {
            _originalPhotoButton.frame = CGRectMake((CGRectGetWidth(_toolBar.frame)-width)/2-fullImageWidth/2, 0, width, 44);
            _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
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
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 42, 0, 80, 44);
        if (!imagePickerVc.allowEditting) { /** 非编辑模式 原图显示在左边 */
            _originalPhotoLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
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
    
    CGSize doneSize = [[imagePickerVc.doneBtnTitleStr stringByAppendingString:@"(10)" ] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size;
    doneSize.height = MIN(MAX(doneSize.height, CGRectGetHeight(_toolBar.frame)), 30);
    doneSize.width += 4;
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(self.view.width - doneSize.width - 12, (CGRectGetHeight(_toolBar.frame)-doneSize.height)/2, doneSize.width, doneSize.height);
    _doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
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
    divide.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    [_toolBar addSubview:_editButton];
    [_toolBar addSubview:_originalPhotoButton];
    [_toolBar addSubview:_doneButton];
    [_toolBar addSubview:divide];
    [self.view addSubview:_toolBar];
}

- (void)configPreviewBar {
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    _previewBar = [[LFPreviewBar alloc] initWithFrame:CGRectMake(0, self.view.height - _toolBar.height - 64, self.view.width, 64)];
    _previewBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _previewBar.backgroundColor = imagePickerVc.toolbarBgColor;
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
    [self.view addSubview:_previewBar];
}

- (void)configLivePhotoSign
{
    CGFloat naviHeight = [self navigationHeight];
    _livePhotoSignView = [[UIView alloc] initWithFrame:CGRectMake(livePhotoSignMargin, livePhotoSignMargin + naviHeight, 30, 30)];
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
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
            [imagePickerVc.selectedModels addObject:model];
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
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

- (void)editButtonClick {
    if (self.models.count > self.currentIndex) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        LFPhotoEditingController *photoEdittingVC = [[LFPhotoEditingController alloc] init];
        if (imagePickerVc.edit_oKButtonTitleColorNormal) {
            photoEdittingVC.oKButtonTitleColorNormal = imagePickerVc.edit_oKButtonTitleColorNormal;
        }
        if (imagePickerVc.edit_cancelButtonTitleColorNormal) {
            photoEdittingVC.cancelButtonTitleColorNormal = imagePickerVc.edit_cancelButtonTitleColorNormal;
        }
        if (imagePickerVc.edit_oKButtonTitle) {
            photoEdittingVC.oKButtonTitle = imagePickerVc.edit_oKButtonTitle;
        }
        if (imagePickerVc.edit_cancelButtonTitle) {
            photoEdittingVC.cancelButtonTitle = imagePickerVc.edit_cancelButtonTitle;
        }
        if (imagePickerVc.edit_processHintStr) {
            photoEdittingVC.processHintStr = imagePickerVc.edit_processHintStr;
        }
        
        /** 获取缓存编辑对象 */
        LFAsset *model = [self.models objectAtIndex:self.currentIndex];
        LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
        if (photoEdit) {
            photoEdittingVC.photoEdit = photoEdit;
        } else {
            /** 当前页面只显示一张图片 */
            LFPhotoPreviewCell *cell = [_collectionView visibleCells].firstObject;
            /** 当前显示的图片 */
            photoEdittingVC.editImage = cell.previewImage;
        }
        photoEdittingVC.delegate = self;
        [imagePickerVc pushViewController:photoEdittingVC animated:NO];
    }
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    imagePickerVc.isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_originalPhotoButton.selected) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    // show or hide naviBar / 显示或隐藏导航栏
    self.isHideMyNaviBar = !self.isHideMyNaviBar;
    CGFloat alpha = self.isHideMyNaviBar ? 0.f : 1.f;
    [UIView animateWithDuration:0.25f animations:^{
        _naviBar.alpha = alpha;
        _toolBar.alpha = alpha;
        /** 非总是显示模式，并且 预览栏数量为0时，已经是被隐藏，不能显示, 取反操作 */
        if (!(!self.alwaysShowPreviewBar && _previewBar.dataSource.count == 0)) {
            _previewBar.alpha = alpha;
        }
        
        /** live photo 标记 */
        if (imagePickerVc.allowPickingLivePhoto && cell.model.subType == LFAssetSubMediaTypeLivePhoto) {
            _livePhotoSignView.alpha = alpha;
        }
    }];
}

#pragma mark - LFPhotoEditingControllerDelegate
- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEdittingVC didCancelPhotoEdit:(LFPhotoEdit *)photoEdit
{
    if (photoEdit == nil && _collectionView == nil) { /** 没有编辑 并且 UI未初始化 */
        self.tempEditImage = photoEdittingVC.editImage;
    }
    
    [self.navigationController popViewControllerAnimated:NO];
}
- (void)lf_PhotoEditingController:(LFPhotoEditingController *)photoEdittingVC didFinishPhotoEdit:(LFPhotoEdit *)photoEdit
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
                cell.previewImage = photoEdittingVC.editImage;
            } else { /** UI未初始化，记录当前编辑图片，初始化后设置 */
                self.tempEditImage = photoEdittingVC.editImage;
            }
        }
        
        /** 默认选中编辑后的图片 */
        if (!_selectButton.isSelected) {
            [self select:_selectButton];
        }
        
        [self.navigationController popViewControllerAnimated:NO];
    }
}

#pragma mark - Private Method

- (void)refreshNaviBarAndBottomBarState {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    LFAsset *model = _models[_currentIndex];
    _selectButton.selected = model.isSelected;
    if (_selectButton.selected) {
        NSString *text = [NSString stringWithFormat:@"%ld", [imagePickerVc.selectedModels indexOfObject:model]+1];
        UIImage *image = [UIImage lf_mergeImage:bundleImageNamed(imagePickerVc.photoNumberIconImageName) text:text];
        [_selectButton setImage:image forState:UIControlStateSelected];
    }
    
    _doneButton.enabled = !self.alwaysShowPreviewBar || imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    if (imagePickerVc.selectedModels.count) {
        [_doneButton setTitle:[NSString stringWithFormat:@"%@(%zd)",imagePickerVc.doneBtnTitleStr ,imagePickerVc.selectedModels.count] forState:UIControlStateNormal];
    } else {
        [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    }
    
    _originalPhotoButton.hidden = model.type == LFAssetMediaTypeVideo;
    /** 视频编辑 */
    _editButton.hidden = model.type == LFAssetMediaTypeVideo;
    
    _originalPhotoLabel.hidden = !(_originalPhotoButton.selected && imagePickerVc.selectedModels.count > 0);
    if (_originalPhotoButton.selected) [self showPhotoBytes];
    
    /** 关闭编辑 已选数量达到最大限度 && 非选中图片  */
    _editButton.enabled = (imagePickerVc.selectedModels.count != imagePickerVc.maxImagesCount || model.isSelected);
    
    /** 预览栏动画 */
    if (!self.alwaysShowPreviewBar) {
        if (imagePickerVc.selectedModels.count) {
            [UIView animateWithDuration:0.25f animations:^{
                _previewBar.alpha = 1.f;
            }];
        } else {
            [UIView animateWithDuration:0.25f animations:^{
                _previewBar.alpha = 0.f;
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
