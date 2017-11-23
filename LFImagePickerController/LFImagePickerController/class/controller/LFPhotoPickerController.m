//
//  LFPhotoPickerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPickerController.h"
#import "LFImagePickerController.h"
#import "LFPhotoPreviewController.h"

#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "UIImage+LFCommon.h"
#import "UIImage+LF_Format.h"

#import "LFAlbum.h"
#import "LFAsset.h"
#import "LFAssetCell.h"
#import "LFAssetManager+Authorization.h"
#import "LFAssetManager+SaveAlbum.h"

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"
#import "LFVideoEditManager.h"
#import "LFVideoEdit.h"
#endif

#import <MobileCoreServices/UTCoreTypes.h>

#define kBottomToolBarHeight 50.f

@interface LFCollectionView : UICollectionView

@end

@implementation LFCollectionView

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ( [view isKindOfClass:[UIControl class]]) {
        return YES;
    }
    return [super touchesShouldCancelInContentView:view];
}

@end

@interface LFPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    UIView *_bottomToolBar;
    UIView *_bottomSubToolBar;
    UIButton *_editButton;
    UIButton *_previewButton;
    UIButton *_doneButton;
    
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
}
@property (nonatomic, weak) UIView *nonePhotoView;

@property (nonatomic, strong) NSMutableArray *models;

@property (nonatomic, strong) LFCollectionView *collectionView;

@end

@interface LFPhotoPickerController () <UIViewControllerPreviewingDelegate, PHPhotoLibraryChangeObserver>

@end

@implementation LFPhotoPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    if (!imagePickerVc.isPreview) { /** 非预览模式 */
        
        _shouldScrollToBottom = YES;
        self.view.backgroundColor = [UIColor whiteColor];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:imagePickerVc.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:imagePickerVc action:@selector(cancelButtonClick)];
#pragma clang diagnostic pop
        /** 优先赋值 */
        self.navigationItem.title = _model.name;
        [imagePickerVc showProgressHUD];
        
        __weak typeof(self) weakSelf = self;
        dispatch_globalQueue_async_safe(^{
            
            long long start = [[NSDate date] timeIntervalSince1970] * 1000;
            void (^initDataHandle)() = ^{
                if (weakSelf.model) {
                    if (weakSelf.model.models.count) { /** 使用缓存数据 */
                        weakSelf.models = [NSMutableArray arrayWithArray:weakSelf.model.models];
                        /** check selected data */
                        [weakSelf checkSelectedModels];
                        dispatch_main_async_safe(^{
                            [weakSelf initSubviews];
                        });
                    } else {
                        /** 倒序情况下。iOS9的result已支持倒序,这里的排序应该为顺序 */
                        BOOL ascending = imagePickerVc.sortAscendingByCreateDate;
                        if (!imagePickerVc.sortAscendingByCreateDate && iOS8Later) {
                            ascending = !imagePickerVc.sortAscendingByCreateDate;
                        }
                        [[LFAssetManager manager] getAssetsFromFetchResult:weakSelf.model.result allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:ascending completion:^(NSArray<LFAsset *> *models) {
                            /** 缓存数据 */
                            weakSelf.model.models = models;
                            weakSelf.models = [NSMutableArray arrayWithArray:models];
                            [weakSelf checkDefaultSelectedModels];
                            dispatch_main_async_safe(^{
                                long long end = [[NSDate date] timeIntervalSince1970] * 1000;
                                NSLog(@"%luPhoto loading time-consuming: %lld milliseconds", (unsigned long)models.count, end - start);
                                [weakSelf initSubviews];
                            });
                        }];
                    }
                } else {
                    dispatch_main_async_safe(^{
                        [weakSelf initSubviews];
                    });
                }
            };
            
            if (_model == nil) { /** 没有指定相册，默认显示相片胶卷 */
                if (imagePickerVc.defaultAlbumName) { /** 有指定相册 */
                    [[LFAssetManager manager] getAllAlbums:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage ascending:imagePickerVc.sortAscendingByCreateDate completion:^(NSArray<LFAlbum *> *models) {
                        for (LFAlbum *album in models) {
                            if (album.count) {
                                if ([[album.name lowercaseString] isEqualToString:[imagePickerVc.defaultAlbumName lowercaseString]]) {
                                    weakSelf.model = album;
                                    break;
                                }
                            }
                        }
                        long long end = [[NSDate date] timeIntervalSince1970] * 1000;
                        NSLog(@"Loading album time-consuming: %lld milliseconds", end - start);
                        initDataHandle();
                    }];
                } else {
                    [[LFAssetManager manager] getCameraRollAlbum:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:imagePickerVc.sortAscendingByCreateDate completion:^(LFAlbum *model) {
                        weakSelf.model = model;
                        long long end = [[NSDate date] timeIntervalSince1970] * 1000;
                        NSLog(@"Loading album time-consuming: %lld milliseconds", end - start);
                        initDataHandle();
                    }];
                }
            } else { /** 已存在相册数据 */
                initDataHandle();
            }
        });
        
        if (imagePickerVc.syncAlbum) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];    //创建监听者
        }
    }
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGFloat toolbarHeight = kBottomToolBarHeight;
    if (@available(iOS 11.0, *)) {
        toolbarHeight += self.view.safeAreaInsets.bottom;
    }
    
    CGRect collectionViewRect = [self viewFrameWithoutNavigation];
    collectionViewRect.size.height -= toolbarHeight;
    if (@available(iOS 11.0, *)) {
        collectionViewRect.origin.x += self.view.safeAreaInsets.left;
        collectionViewRect.size.width -= self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
    }
    _collectionView.frame = collectionViewRect;
    
    /* 适配底部栏 */
    CGFloat yOffset = self.view.height - toolbarHeight;
    _bottomToolBar.frame = CGRectMake(0, yOffset, self.view.width, toolbarHeight);
    
    CGRect bottomToolbarRect = _bottomToolBar.bounds;
    if (@available(iOS 11.0, *)) {
        bottomToolbarRect.origin.x += self.view.safeAreaInsets.left;
        bottomToolbarRect.size.width -= self.view.safeAreaInsets.left + self.view.safeAreaInsets.right;
    }
    _bottomSubToolBar.frame = bottomToolbarRect;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (imagePickerVc.syncAlbum) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];    //移除监听者
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)initSubviews {
    /** 可能没有model的情况，补充赋值 */
    self.navigationItem.title = _model.name;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
    _showTakePhotoBtn = (([[LFAssetManager manager] isCameraRollAlbum:_model.name]) && imagePickerVc.allowTakePicture);
    
    
    if (_models.count == 0) {
        [self configNonePhotoView];
    } else {
        [self configCollectionView];
        [self configBottomToolBar];
        [self scrollCollectionViewToBottom];
    }
    
}

- (void)configNonePhotoView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    UIView *nonePhotoView = [[UIView alloc] initWithFrame:[self viewFrameWithoutNavigation]];
    nonePhotoView.backgroundColor = [UIColor clearColor];
    
    NSString *text = @"没有图片或视频";
    if (!imagePickerVc.allowPickingImage && imagePickerVc.allowPickingVideo) {
        text = @"没有视频";
    } else if (imagePickerVc.allowPickingImage && !imagePickerVc.allowPickingVideo) {
        text = @"没有图片";
    }
    UIFont *font = [UIFont systemFontOfSize:18];
    
    UILabel *label = [[UILabel alloc] initWithFrame:nonePhotoView.bounds];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = font;
    label.text = text;
    label.textColor = [UIColor lightGrayColor];
    
    [nonePhotoView addSubview:label];
    nonePhotoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:nonePhotoView];
    self.nonePhotoView = nonePhotoView;
}

- (void)configCollectionView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = isiPad ? 15 : 8;
    CGFloat screenWidth = MIN(self.view.width, self.view.height);
    CGFloat itemWH = (screenWidth - (imagePickerVc.columnNumber + 1) * margin) / imagePickerVc.columnNumber;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    
    CGRect collectionViewRect = [self viewFrameWithoutNavigation];
    CGFloat toolbarHeight = kBottomToolBarHeight;
    if (@available(iOS 11.0, *)) {
        toolbarHeight += self.view.safeAreaInsets.bottom;
    }
    collectionViewRect.size.height -= toolbarHeight;
    
    _collectionView = [[LFCollectionView alloc] initWithFrame:collectionViewRect collectionViewLayout:layout];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    
    if (_showTakePhotoBtn && imagePickerVc.allowTakePicture ) {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + imagePickerVc.columnNumber) / imagePickerVc.columnNumber) * self.view.width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + imagePickerVc.columnNumber - 1) / imagePickerVc.columnNumber) * self.view.width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[LFAssetCell class] forCellWithReuseIdentifier:@"LFAssetPhotoCell"];
    [_collectionView registerClass:[LFAssetCell class] forCellWithReuseIdentifier:@"LFAssetVideoCell"];
    [_collectionView registerClass:[LFAssetCameraCell class] forCellWithReuseIdentifier:@"LFAssetCameraCell"];
}

- (void)configBottomToolBar {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat height = kBottomToolBarHeight;
    if (@available(iOS 11.0, *)) {
        height += self.view.safeAreaInsets.bottom;
    }
    CGFloat yOffset = self.view.height - height;
    
    UIColor *toolbarBGColor = imagePickerVc.toolbarBgColor;
    UIColor *toolbarTitleColorNormal = imagePickerVc.toolbarTitleColorNormal;
    UIColor *toolbarTitleColorDisabled = imagePickerVc.toolbarTitleColorDisabled;
    UIFont *toolbarTitleFont = imagePickerVc.toolbarTitleFont;
    
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, self.view.width, height)];
    bottomToolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    bottomToolBar.backgroundColor = toolbarBGColor;
    
    UIView *bottomSubToolBar = [[UIView alloc] initWithFrame:bottomToolBar.bounds];
    bottomSubToolBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [bottomToolBar addSubview:bottomSubToolBar];
    _bottomSubToolBar = bottomSubToolBar;
    
    CGFloat buttonX = 0;
    
//    if (imagePickerVc.allowEditing) {
//        CGFloat editWidth = [imagePickerVc.editBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width + 2;
//        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _editButton.frame = CGRectMake(10, 3, editWidth, 44);
//        _editButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
//        [_editButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
//        _editButton.titleLabel.font = toolbarTitleFont;
//        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateNormal];
//        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateDisabled];
//        [_editButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
//        [_editButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
//        _editButton.enabled = imagePickerVc.selectedModels.count==1;
//        
//        buttonX = CGRectGetMaxX(_editButton.frame);
//    }
    
    
    if (imagePickerVc.allowPreview) {
        CGSize previewSize = [imagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size;
        previewSize.width += 2.f;
        _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _previewButton.frame = CGRectMake(buttonX+10, (kBottomToolBarHeight-previewSize.height)/2, previewSize.width, previewSize.height);
        _previewButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _previewButton.titleLabel.font = toolbarTitleFont;
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateNormal];
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateDisabled];
        [_previewButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_previewButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
        _previewButton.enabled = imagePickerVc.selectedModels.count;
        
        buttonX = CGRectGetMaxX(_previewButton.frame);
    }
    
    
    if (imagePickerVc.allowPickingOriginalPhoto && imagePickerVc.isPreview==NO) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat originalButtonW = fullImageWidth + 56;
        _originalPhotoButton.frame = CGRectMake((CGRectGetWidth(bottomToolBar.frame)-originalButtonW)/2, 0, originalButtonW, kBottomToolBarHeight);
        _originalPhotoButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = toolbarTitleFont;
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateDisabled];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:toolbarTitleColorNormal forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:toolbarTitleColorDisabled forState:UIControlStateDisabled];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateNormal];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginSelImageName) forState:UIControlStateSelected];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateDisabled];
        _originalPhotoButton.selected = imagePickerVc.isSelectOriginalPhoto;
//        _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, kBottomToolBarHeight);
        _originalPhotoLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = toolbarTitleFont;
        _originalPhotoLabel.textColor = toolbarTitleColorNormal;
        
        [_originalPhotoButton addSubview:_originalPhotoLabel];
        if (_originalPhotoButton.selected) [self getSelectedPhotoBytes];
    }
    
    CGSize doneSize = [[imagePickerVc.doneBtnTitleStr stringByAppendingFormat:@"(%ld)", (long)imagePickerVc.maxImagesCount] boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:toolbarTitleFont} context:nil].size;
    doneSize.height = MIN(MAX(doneSize.height, height), 30);
    doneSize.width += 4;
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(self.view.width - doneSize.width - 12, (kBottomToolBarHeight-doneSize.height)/2, doneSize.width, doneSize.height);
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
    
    [bottomSubToolBar addSubview:_editButton];
    [bottomSubToolBar addSubview:_previewButton];
    [bottomSubToolBar addSubview:_originalPhotoButton];
    [bottomSubToolBar addSubview:_doneButton];
    [bottomSubToolBar addSubview:divide];
    [self.view addSubview:bottomToolBar];
    _bottomToolBar = bottomToolBar;
    
    [self refreshBottomToolBarStatus];
}

#pragma mark - Click Event
//- (void)editButtonClick {
//    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
//    NSArray *models = [imagePickerVc.selectedModels copy];
//    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:_models index:[_models indexOfObject:models.firstObject] excludeVideo:NO];
//    LFPhotoEditingController *photoEditingVC = [[LFPhotoEditingController alloc] init];
//    
//    /** 抽取第一个对象 */
//    LFAsset *model = models.firstObject;
//    /** 获取缓存编辑对象 */
//    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
//    if (photoEdit) {
//        photoEditingVC.photoEdit = photoEdit;
//    } else if (model.previewImage) { /** 读取自定义图片 */
//        photoEditingVC.editImage = model.previewImage;
//    } else {
//        /** 获取对应的图片 */
//        [[LFAssetManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
//            photoEditingVC.editImage = photo;
//        }];
//    }
//    [self pushPhotoPrevireViewController:photoPreviewVc photoEditingViewController:photoEditingVC];
//}

- (void)previewButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSArray *models = [imagePickerVc.selectedModels copy];
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:models index:0];
    photoPreviewVc.alwaysShowPreviewBar = YES;
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    imagePickerVc.isSelectOriginalPhoto = _originalPhotoButton.isSelected;;
    if (_originalPhotoButton.selected) {
        [self getSelectedPhotoBytes];
    } else {
        _originalPhotoLabel.text = nil;
    }
    
}

- (void)doneButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    // 1.6.8 判断是否满足最小必选张数的限制
    if (imagePickerVc.minImagesCount && imagePickerVc.selectedModels.count < imagePickerVc.minImagesCount) {
        NSString *title = [NSString stringWithFormat:@"请至少选择%zd张照片", imagePickerVc.minImagesCount];
        [imagePickerVc showAlertWithTitle:title];
        return;
    }
    
    [imagePickerVc showProgressHUD];
    NSMutableArray *resultArray = [NSMutableArray array];
    
    
    for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) { [resultArray addObject:@1];}
    
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_globalQueue_async_safe(^{
        
        if (imagePickerVc.selectedModels.count) {
            void (^photosComplete)(LFResultObject *, NSInteger) = ^(LFResultObject *result, NSInteger index) {
                if (result) [resultArray replaceObjectAtIndex:index withObject:result];
                
                if ([resultArray containsObject:@1]) return;
                
                dispatch_main_async_safe(^{
                    if (weakSelf == nil) return ;
                    [imagePickerVc hideProgressHUD];
                    if (imagePickerVc.autoDismiss) {
                        [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                            [weakSelf callDelegateMethodWithResults:resultArray];
                        }];
                    } else {
                        [weakSelf callDelegateMethodWithResults:resultArray];
                    }
                });
            };
            
            
            for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) {
                LFAsset *model = imagePickerVc.selectedModels[i];
                
                if (model.type == LFAssetMediaTypePhoto) {
#ifdef LF_MEDIAEDIT
                    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
                    if (photoEdit) {
                        [[LFPhotoEditManager manager] getPhotoWithAsset:model.asset
                                                             isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                           compressSize:imagePickerVc.imageCompressSize
                                                  thumbnailCompressSize:imagePickerVc.thumbnailCompressSize
                                                             completion:^(LFResultImage *resultImage) {
                                                                 
                                                                 if (imagePickerVc.autoSavePhotoAlbum) {
                                                                     /** 编辑图片保存到相册 */
                                                                     [[LFAssetManager manager] saveImageToCustomPhotosAlbumWithTitle:nil images:@[resultImage.originalImage] complete:nil];
                                                                 }
                                                                 photosComplete(resultImage, i);
                                                             }];
                    } else {
#endif
                        if (imagePickerVc.allowPickingLivePhoto && model.subType == LFAssetSubMediaTypeLivePhoto && model.closeLivePhoto == NO) {
                            [[LFAssetManager manager] getLivePhotoWithAsset:model.asset
                                                                 isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                                 completion:^(LFResultImage *resultImage) {
                                                                     
                                                                     photosComplete(resultImage, i);
                                                                 }];
                        } else {
                            [[LFAssetManager manager] getPhotoWithAsset:model.asset
                                                             isOriginal:imagePickerVc.isSelectOriginalPhoto
                                                             pickingGif:imagePickerVc.allowPickingGif
                                                           compressSize:imagePickerVc.imageCompressSize
                                                  thumbnailCompressSize:imagePickerVc.thumbnailCompressSize
                                                             completion:^(LFResultImage *resultImage) {
                                                                 
                                                                 photosComplete(resultImage, i);
                                                             }];
                        }
#ifdef LF_MEDIAEDIT
                    }
#endif
                } else if (model.type == LFAssetMediaTypeVideo) {
#ifdef LF_MEDIAEDIT
                    LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:model];
                    if (videoEdit) {
                        [[LFVideoEditManager manager] getVideoWithAsset:model.asset completion:^(LFResultVideo *resultVideo) {
                            if (imagePickerVc.autoSavePhotoAlbum) {
                                /** 编辑视频保存到相册 */
                                [[LFAssetManager manager] saveVideoToCustomPhotosAlbumWithTitle:nil videoURLs:@[resultVideo.url] complete:nil];
                            }
                            photosComplete(resultVideo, i);
                        }];
                    } else {
#endif
                        [[LFAssetManager manager] getVideoResultWithAsset:model.asset completion:^(LFResultVideo *resultVideo) {
                            photosComplete(resultVideo, i);
                        }];
#ifdef LF_MEDIAEDIT
                    }
#endif
                }
            }
        } else {
            dispatch_main_async_safe(^{
                [imagePickerVc hideProgressHUD];
                if (imagePickerVc.autoDismiss) {
                    [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                        [weakSelf callDelegateMethodWithResults:resultArray];
                    }];
                } else {
                    [weakSelf callDelegateMethodWithResults:resultArray];
                }
            });
        }
    });
    
}

- (void)callDelegateMethodWithResults:(NSArray <LFResultObject *>*)results {
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    id <LFImagePickerControllerDelegate> pickerDelegate = (id <LFImagePickerControllerDelegate>)imagePickerVc.pickerDelegate;
    
    
    if (imagePickerVc.didFinishPickingResultHandle) {
        imagePickerVc.didFinishPickingResultHandle(results);
    } else if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingResult:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingResult:results];
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_showTakePhotoBtn) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        if (imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture) {
            return _models.count + 1;
        }
    }
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // the cell lead to take a picture / 去拍照的cell
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (((imagePickerVc.sortAscendingByCreateDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByCreateDate && indexPath.row == 0)) && _showTakePhotoBtn) {
        LFAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCameraCell" forIndexPath:indexPath];
        cell.posterImage = bundleImageNamed(imagePickerVc.takePictureImageName);
        
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    LFAssetCell *cell = nil;
    
    NSInteger index = indexPath.row - 1;
    if (imagePickerVc.sortAscendingByCreateDate || !_showTakePhotoBtn) {
        index = indexPath.row;
    }
    LFAsset *model = _models[index];
    
    if (model.type == LFAssetMediaTypePhoto) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetPhotoCell" forIndexPath:indexPath];
    } else if (model.type == LFAssetMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetVideoCell" forIndexPath:indexPath];
    }
    
    if (iOS9Later) {
        /** 给cell注册 3DTouch的peek（预览）和pop功能 */
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            //给cell注册3DTouch的peek（预览）和pop功能
            [self registerForPreviewingWithDelegate:self sourceView:cell];
        }
    }

    
    cell.photoDefImageName = imagePickerVc.photoDefImageName;
    cell.photoSelImageName = imagePickerVc.photoNumberIconImageName;
    cell.displayGif = imagePickerVc.allowPickingGif;
    cell.displayLivePhoto = imagePickerVc.allowPickingLivePhoto;
    cell.displayPhotoName = imagePickerVc.displayImageFilename;
    cell.onlySelected = !imagePickerVc.allowPreview;
    /** 最大数量时，非选择部分显示不可选 */
    cell.noSelected = (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount && ![imagePickerVc.selectedModels containsObject:model]);
    
    cell.model = model;
    [cell selectPhoto:model.isSelected index:[imagePickerVc.selectedModels indexOfObject:model]+1 animated:NO];
    
    __weak typeof(self) weakSelf = self;
    cell.didSelectPhotoBlock = ^(BOOL isSelected, LFAsset *cellModel, LFAssetCell *weakCell) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)weakSelf.navigationController;
        // 1. cancel select / 取消选择
        if (!isSelected) {
            cellModel.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:imagePickerVc.selectedModels];
            for (LFAsset *model_item in selectedModels) {
                if ([[[LFAssetManager manager] getAssetIdentifier:cellModel.asset] isEqualToString:[[LFAssetManager manager] getAssetIdentifier:model_item.asset]]) {
                    [imagePickerVc.selectedModels removeObject:model_item];
                    break;
                }
            }
            [weakSelf refreshBottomToolBarStatus];
            
            if (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount-1) {
                /** 取消选择为最大数量-1时，显示其他可选 */
                NSMutableArray<NSIndexPath *> *visibleIPs = [[weakSelf.collectionView indexPathsForVisibleItems] mutableCopy];
                NSIndexPath *cellIndexPath = [weakSelf.collectionView indexPathForCell:weakCell];
                [visibleIPs removeObject:cellIndexPath];
                if (visibleIPs.count) {
                    [weakSelf.collectionView reloadItemsAtIndexPaths:visibleIPs];
                }
            } else {
                [weakSelf refreshSelectedCell];
            }
            
            [weakCell selectPhoto:NO index:0 animated:NO];
            
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePickerVc.selectedModels.count < imagePickerVc.maxImagesCount) {
                
                /** 检测是否超过视频最大时长 */
                if (cellModel.type == LFAssetMediaTypeVideo && cellModel.duration > imagePickerVc.maxVideoDuration) {
                    [imagePickerVc showAlertWithTitle:[NSString stringWithFormat:@"不能选择超过%d分钟的视频", (int)imagePickerVc.maxVideoDuration/60]];
                    return;
                }
                cellModel.isSelected = YES;
                [imagePickerVc.selectedModels addObject:cellModel];
                [weakSelf refreshBottomToolBarStatus];
                
                if (imagePickerVc.selectedModels.count == imagePickerVc.maxImagesCount) {
                    /** 选择到最大数量，禁止其他的可选显示 */
                    [weakSelf refreshNoSelectedCell];
                }
                
                [weakCell selectPhoto:YES index:imagePickerVc.selectedModels.count animated:YES];
                
            } else {
                NSString *title = [NSString stringWithFormat:@"你最多只能选择%zd张照片", imagePickerVc.maxImagesCount];
                [imagePickerVc showAlertWithTitle:title];
            }
        }
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // take a photo / 去拍照
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (((imagePickerVc.sortAscendingByCreateDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByCreateDate && indexPath.row == 0)) && _showTakePhotoBtn)  {
        [self takePhoto]; return;
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.row;
    if (!imagePickerVc.sortAscendingByCreateDate && _showTakePhotoBtn) {
        index = indexPath.row - 1;
    }
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:[_models copy] index:index];
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

#pragma mark - 拍照图片后执行代理
#pragma mark UIImagePickerControllerDelegate methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUDText:nil isTop:YES];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if (picker.sourceType==UIImagePickerControllerSourceTypeCamera && [mediaType isEqualToString:@"public.image"]){
        UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
        [[LFAssetManager manager] saveImageToCustomPhotosAlbumWithTitle:nil images:@[chosenImage] complete:^(NSArray<id> *assets, NSError *error) {
            
            if (assets && !error) {
                [[LFAssetManager manager] getPhotoWithAsset:assets.lastObject isOriginal:YES completion:^(LFResultImage *resultImage) {
                    [imagePickerVc hideProgressHUD];
                    [picker.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        [self callDelegateMethodWithResults:@[resultImage]];
                    }];
                }];
            }else if (error) {
                [imagePickerVc hideProgressHUD];
                [imagePickerVc showAlertWithTitle:@"拍照错误" message:error.localizedDescription complete:^{
                    [picker dismissViewControllerAnimated:YES completion:nil];
                }];
            }
        }];
    } else {
        [imagePickerVc hideProgressHUD];
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerPreviewingDelegate
/** peek(预览) */
- (nullable UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
    //获取按压的cell所在行，[previewingContext sourceView]就是按压的那个视图
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    LFAssetCell *cell = (LFAssetCell* )[previewingContext sourceView];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        // preview phote or video / 预览照片或视频
        NSInteger index = indexPath.row;
        if (!imagePickerVc.sortAscendingByCreateDate && _showTakePhotoBtn) {
            index = indexPath.row - 1;
        }
        LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:[_models copy] index:index];
        [photoPreviewVc beginPreviewing:imagePickerVc];
        
        PHAsset *phAsset = cell.model.asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = [UIScreen mainScreen].bounds.size.width * 2.0f;
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        CGSize imageSize = CGSizeMake(pixelWidth, pixelHeight);
        
        CGSize contentSize = [UIImage lf_scaleImageSizeBySize:imageSize targetSize:CGSizeMake(self.view.bounds.size.width, self.view.bounds.size.height) isBoth:NO];
        photoPreviewVc.preferredContentSize = CGSizeMake(contentSize.width, contentSize.height);
        return photoPreviewVc;
    }
    return nil;
}

/** pop（按用点力进入） */
- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
    LFPhotoPreviewController *photoPreviewVc = (LFPhotoPreviewController *)viewControllerToCommit;
    [self pushPhotoPrevireViewController:photoPreviewVc];
    [photoPreviewVc endPreviewing];
}


#pragma mark - Private Method

- (void)takePhoto {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) && iOS7Later) {
        // 无权限 做一个友好的提示
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *message = [NSString stringWithFormat:@"请在\"设置-隐私-相机\"中允许%@访问相机",appName];
        [imagePickerVc showAlertWithTitle:nil cancelTitle:@"设置" message:message complete:^{
            if (iOS8Later) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            } else {
                NSString *message = @"无法跳转到隐私设置页面，请手动前往设置页面，谢谢";
                [imagePickerVc showAlertWithTitle:nil message:message complete:^{
                }];
            }
        }];
        
    } else { // 调用相机
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(lf_imagePickerControllerTakePhoto:)]) {
                [imagePickerVc.pickerDelegate lf_imagePickerControllerTakePhoto:imagePickerVc];
            } else if (imagePickerVc.imagePickerControllerTakePhoto) {
                imagePickerVc.imagePickerControllerTakePhoto();
            } else {
                /** 调用内置相机模块 */
                UIImagePickerControllerSourceType srcType = UIImagePickerControllerSourceTypeCamera;
                UIImagePickerController *mediaPickerController = [[UIImagePickerController alloc] init];
                mediaPickerController.sourceType = srcType;
                mediaPickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                mediaPickerController.delegate = self;
                mediaPickerController.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
                
                /** warning：Snapshotting a view that has not been rendered results in an empty snapshot. Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates. */
                [self presentViewController:mediaPickerController animated:YES completion:NULL];
            }
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

- (void)refreshSelectedCell
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSMutableArray <NSIndexPath *>*indexPaths = [NSMutableArray array];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(LFAssetCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[LFAssetCell class]] && [imagePickerVc.selectedModels containsObject:cell.model]) {
            NSInteger index = [_models indexOfObject:cell.model];
            if (_showTakePhotoBtn && !imagePickerVc.sortAscendingByCreateDate) {
                index += 1;
            }
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }];
    if (indexPaths.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)refreshNoSelectedCell
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSMutableArray <NSIndexPath *>*indexPaths = [NSMutableArray array];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(LFAssetCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[LFAssetCell class]] && ![imagePickerVc.selectedModels containsObject:cell.model]) {
            NSInteger index = [_models indexOfObject:cell.model];
            if (_showTakePhotoBtn && !imagePickerVc.sortAscendingByCreateDate) {
                index += 1;
            }
            [indexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        }
    }];
    if (indexPaths.count) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    }
}

- (void)refreshBottomToolBarStatus {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    _editButton.enabled = imagePickerVc.selectedModels.count == 1;
    _previewButton.enabled = imagePickerVc.selectedModels.count > 0;
//    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    _doneButton.backgroundColor = _doneButton.enabled ? imagePickerVc.oKButtonTitleColorNormal : imagePickerVc.oKButtonTitleColorDisabled;
    
    [_doneButton setTitle:[NSString stringWithFormat:@"%@(%zd)",imagePickerVc.doneBtnTitleStr ,imagePickerVc.selectedModels.count] forState:UIControlStateNormal];
    
//    _originalPhotoButton.selected = (imagePickerVc.isSelectOriginalPhoto && imagePickerVc.selectedModels.count > 0);
    _originalPhotoLabel.hidden = !(_originalPhotoButton.selected && imagePickerVc.selectedModels.count > 0);
    if (_originalPhotoButton.selected) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc {
    
    __weak typeof(self) weakSelf = self;
    [photoPreviewVc setBackButtonClickBlock:^{
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^{
        [weakSelf doneButtonClick];
    }];
    
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

//- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc photoEditingViewController:(LFPhotoEditingController *)photoEditingVC {
//
//    /** 关联代理 */
//    photoEditingVC.delegate = (id)photoPreviewVc;
//
//    __weak typeof(self) weakSelf = self;
//    [photoPreviewVc setBackButtonClickBlock:^{
//        [weakSelf.collectionView reloadData];
//        [weakSelf refreshBottomToolBarStatus];
//    }];
//    [photoPreviewVc setDoneButtonClickBlock:^{
//        [weakSelf doneButtonClick];
//    }];
//
//    if (photoEditingVC) {
//        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
//        [viewControllers addObject:photoPreviewVc];
//        [viewControllers addObject:photoEditingVC];
//        [self.navigationController setViewControllers:viewControllers animated:YES];
//    } else {
//        [self.navigationController pushViewController:photoPreviewVc animated:YES];
//    }
//}


- (void)getSelectedPhotoBytes {
    if (/* DISABLES CODE */ (1)==0) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        [[LFAssetManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
            _originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
        }];
    }
}

- (void)scrollCollectionViewToBottom {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (_shouldScrollToBottom && _models.count > 0 && imagePickerVc.sortAscendingByCreateDate) {
        NSInteger item = _models.count - 1;
        if (_showTakePhotoBtn) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            if (imagePickerVc.allowPickingImage && imagePickerVc.allowTakePicture) {
                item += 1;
            }
        }
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        _shouldScrollToBottom = NO;
    }
}

- (void)checkSelectedModels {
    NSMutableArray *selectedAssets = [NSMutableArray array];
    NSMutableArray *selectedModels = [NSMutableArray array];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    for (LFAsset *model in imagePickerVc.selectedModels) {
        if (model.asset) {
            [selectedAssets addObject:model.asset];
        }
        [selectedModels addObject:@1];
    }
    [imagePickerVc.selectedModels removeAllObjects];
    
    for (LFAsset *model in _models) {
        model.isSelected = NO;
        if (selectedAssets.count) {
            NSInteger index = [[LFAssetManager manager] isAssetsArray:selectedAssets containAsset:model.asset];
            if (index != NSNotFound && imagePickerVc.maxImagesCount > imagePickerVc.selectedModels.count) {
                model.isSelected = YES;
                [selectedModels replaceObjectAtIndex:index withObject:model];
            }
        }
    }
    [selectedModels removeObject:@1];
    [imagePickerVc.selectedModels addObjectsFromArray:selectedModels];
}

- (void)checkDefaultSelectedModels {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc.selectedModels removeAllObjects];
    if (imagePickerVc.selectedAssets.count) {
        for (LFAsset *model in _models) {
            model.isSelected = NO;
            NSInteger index = [[LFAssetManager manager] isAssetsArray:imagePickerVc.selectedAssets containAsset:model.asset];
            if (index != NSNotFound && imagePickerVc.maxImagesCount > imagePickerVc.selectedModels.count) {
                model.isSelected = YES;
                [imagePickerVc.selectedModels addObject:model];
            }
        }
    }
    /** 只执行一次 */
    imagePickerVc.selectedAssets = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - PHPhotoLibraryChangeObserver
//相册变化回调
- (void)photoLibraryDidChange:(PHChange *)changeInfo {
    
    
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        PHObjectChangeDetails *albumChanges = [changeInfo changeDetailsForObject:self.model.album];
        if (albumChanges) {
            // Fetch the new album and update the UI accordingly.
            [self.model changedAlbum:[albumChanges objectAfterChanges]];
            self.navigationItem.title = _model.name;
            if (albumChanges.objectWasDeleted) {
                
                void (^showAlertView)() = ^{
                    [imagePickerVc showAlertWithTitle:nil message:@"相册已被删除!" complete:^{
                        if (imagePickerVc.viewControllers.count > 1) {
                            [imagePickerVc popToRootViewControllerAnimated:YES];
                        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                            [imagePickerVc performSelector:@selector(cancelButtonClick)];
#pragma clang diagnostic pop
                        }
                    }];
                };
                
                if (self.presentedViewController) {
                    [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
                        showAlertView();
                    }];
                } else {
                    showAlertView();
                }
                return ;
            }
        }
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        PHFetchResultChangeDetails *collectionChanges = [changeInfo changeDetailsForFetchResult:self.model.result];
        if (collectionChanges) {
            // Get the new fetch result for future change tracking.
            [self.model changedResult:collectionChanges.fetchResultAfterChanges];
            
            if (collectionChanges.hasIncrementalChanges)  {
                // Tell the collection view to animate insertions/deletions/moves
                // and to refresh any cells that have changed content.
                
                BOOL ascending = imagePickerVc.sortAscendingByCreateDate;
                if (!imagePickerVc.sortAscendingByCreateDate && iOS8Later) {
                    ascending = !imagePickerVc.sortAscendingByCreateDate;
                }
                [[LFAssetManager manager] getAssetsFromFetchResult:self.model.result allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:ascending completion:^(NSArray<LFAsset *> *models) {
                    self.model.models = models;
                    self.models = [NSMutableArray arrayWithArray:models];
                    [self checkSelectedModels];
                }];
                
                if (self.nonePhotoView) {
                    [self.nonePhotoView removeFromSuperview];
                    self.nonePhotoView = nil;
                    [self configCollectionView];
                    [self configBottomToolBar];
                    [self scrollCollectionViewToBottom];
                }
                
                [self.collectionView reloadData];
                
                /** 刷新后返回当前UI */
                if (self.presentedViewController) {
                    [self.presentedViewController dismissViewControllerAnimated:NO completion:^{
                        if (imagePickerVc.viewControllers.lastObject != self) {
                            [imagePickerVc popToViewController:self animated:NO];
                        }
                    }];
                } else {
                    if (imagePickerVc.viewControllers.lastObject != self) {
                        [imagePickerVc popToViewController:self animated:NO];
                    }
                }
            } else {
                // Detailed change information is not available;
                // repopulate the UI from the current fetch result.
            }
        }
    });
}

@end
