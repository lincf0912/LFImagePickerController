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
#import "LFPhotoEdittingController.h"
#import "LFVideoPlayerController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "UIAlertView+LF_Block.h"
#import "UIImage+LFCommon.h"

#import "LFAlbum.h"
#import "LFAsset.h"
#import "LFAssetCell.h"
#import "LFAssetManager+Authorization.h"
#import "LFAssetManager+SaveAlbum.h"
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

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
    NSMutableArray *_models;
    
    UIButton *_editButton;
    UIButton *_previewButton;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
}
@property (nonatomic, strong) LFCollectionView *collectionView;

@end

@implementation LFPhotoPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    if (!imagePickerVc.isPreview) { /** 非预览模式 */
        
        _shouldScrollToBottom = YES;
        self.view.backgroundColor = [UIColor whiteColor];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:imagePickerVc.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:imagePickerVc action:@selector(cancelButtonClick)];
        
        /** 优先赋值 */
        self.navigationItem.title = _model.name;
        [imagePickerVc showProgressHUD];
        
        dispatch_globalQueue_async_safe(^{
            if (_model == nil) { /** 没有指定相册，默认显示相片胶卷 */
                [[LFAssetManager manager] getCameraRollAlbum:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:imagePickerVc.sortAscendingByCreateDate completion:^(LFAlbum *model) {
                    self.model = model;
                }];
            }
            
            if (self.model.models.count) { /** 使用缓存数据 */
                _models = [NSMutableArray arrayWithArray:_model.models];
                dispatch_main_async_safe(^{
                    [self initSubviews];
                });
            } else {
                /** 倒序情况下。iOS9的result已支持倒序,这里的排序应该为顺序 */
                BOOL ascending = imagePickerVc.sortAscendingByCreateDate;
                if (!imagePickerVc.sortAscendingByCreateDate && iOS8Later) {
                    ascending = !imagePickerVc.sortAscendingByCreateDate;
                }
                [[LFAssetManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:ascending completion:^(NSArray<LFAsset *> *models) {
                    /** 缓存数据 */
                    _model.models = models;
                    _models = [NSMutableArray arrayWithArray:models];
                    dispatch_main_async_safe(^{
                        [self initSubviews];
                    });
                }];
            }
        });
    }
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
        [self checkSelectedModels];
        [self configCollectionView];
        [self configBottomToolBar];
        [self scrollCollectionViewToBottom];
    }
    
}

- (void)configNonePhotoView {
    CGFloat top = 0;
    CGFloat height = 0;
    if (self.navigationController.navigationBar.isTranslucent) {
        top = 44;
        if (iOS7Later) top += 20;
        height = self.view.height - top;;
    } else {
        CGFloat navigationHeight = 44;
        if (iOS7Later) navigationHeight += 20;
        height = self.view.height - navigationHeight;
    }
    UIView *nonePhotoView = [[UIView alloc] initWithFrame:CGRectMake(0, top, self.view.width, height)];
    nonePhotoView.backgroundColor = [UIColor clearColor];
    
    NSString *text = @"没有图片或视频";
    UIFont *font = [UIFont systemFontOfSize:18];
    CGSize textSize = [text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size;
    
    UILabel *label = [[UILabel alloc] initWithFrame:(CGRect){{(CGRectGetWidth(nonePhotoView.frame)-textSize.width)/2, (CGRectGetHeight(nonePhotoView.frame)-textSize.height)/2}, textSize}];
    label.font = font;
    label.text = text;
    label.textColor = [UIColor lightGrayColor];
    
    [nonePhotoView addSubview:label];
    [self.view addSubview:nonePhotoView];
}

- (void)configCollectionView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = 5;
    CGFloat itemWH = (self.view.width - (imagePickerVc.columnNumber + 1) * margin) / imagePickerVc.columnNumber;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    
    CGFloat top = 0;
    CGFloat collectionViewHeight = 0;
    if (self.navigationController.navigationBar.isTranslucent) {
        top = 44;
        if (iOS7Later) top += 20;
        collectionViewHeight = self.view.height - top;;
    } else {
        CGFloat navigationHeight = 44;
        if (iOS7Later) navigationHeight += 20;
        collectionViewHeight = self.view.height - navigationHeight;
    }
    
    collectionViewHeight -= kBottomToolBarHeight;
    
    _collectionView = [[LFCollectionView alloc] initWithFrame:CGRectMake(0, top, self.view.width, collectionViewHeight) collectionViewLayout:layout];
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
    [_collectionView registerClass:[LFAssetCell class] forCellWithReuseIdentifier:@"LFAssetCell"];
    [_collectionView registerClass:[LFAssetCameraCell class] forCellWithReuseIdentifier:@"LFAssetCameraCell"];
}

- (void)configBottomToolBar {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat yOffset = 0, height = kBottomToolBarHeight;;
    if (self.navigationController.navigationBar.isTranslucent) {
        yOffset = self.view.height - height;
    } else {
        CGFloat navigationHeight = 44;
        if (iOS7Later) navigationHeight += 20;
        yOffset = self.view.height - height - navigationHeight;
    }
    
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, self.view.width, height)];
    CGFloat rgb = 253 / 255.0;
    bottomToolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    CGFloat buttonX = 0;
    
    if (imagePickerVc.allowEditting) {
        
        CGFloat editWidth = [imagePickerVc.editBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 2;
        _editButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _editButton.frame = CGRectMake(10, 3, editWidth, 44);
        [_editButton addTarget:self action:@selector(editButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _editButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateNormal];
        [_editButton setTitle:imagePickerVc.editBtnTitleStr forState:UIControlStateDisabled];
        [_editButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_editButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _editButton.enabled = imagePickerVc.selectedModels.count==1;
        
        buttonX = CGRectGetMaxX(_editButton.frame);
    }
    
    
    if (imagePickerVc.allowPreview) {
        CGFloat previewWidth = [imagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 2;
        _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _previewButton.frame = CGRectMake(buttonX+10, 3, previewWidth, 44);
        [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateNormal];
        [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateDisabled];
        [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        _previewButton.enabled = imagePickerVc.selectedModels.count;
        
        buttonX = CGRectGetMaxX(_previewButton.frame);
    }
    
    
    if (imagePickerVc.allowPickingOriginalPhoto && imagePickerVc.isPreview==NO) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.frame = CGRectMake(buttonX, 0, fullImageWidth + 56, 50);
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateDisabled];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateNormal];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginSelImageName) forState:UIControlStateSelected];
        [_originalPhotoButton setImage:bundleImageNamed(imagePickerVc.photoOriginDefImageName) forState:UIControlStateDisabled];
        _originalPhotoButton.selected = imagePickerVc.isSelectOriginalPhoto;
        _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, 50);
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:16];
        _originalPhotoLabel.textColor = [UIColor blackColor];
        
        [_originalPhotoButton addSubview:_originalPhotoLabel];
        if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.frame = CGRectMake(self.view.width - 44 - 12, 3, 44, 44);
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitle:imagePickerVc.doneBtnTitleStr forState:UIControlStateDisabled];
    [_doneButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    [_doneButton setTitleColor:imagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:bundleImageNamed(imagePickerVc.photoNumberIconImageName)];
    _numberImageView.frame = CGRectMake(self.view.width - 56 - 28, 10, 30, 30);
    _numberImageView.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.frame = _numberImageView.frame;
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePickerVc.selectedModels.count];
    _numberLabel.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    
    UIView *divide = [[UIView alloc] init];
    CGFloat rgb2 = 222 / 255.0;
    divide.backgroundColor = [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];
    divide.frame = CGRectMake(0, 0, self.view.width, 1);
    
    
    [bottomToolBar addSubview:_editButton];
    [bottomToolBar addSubview:_previewButton];
    [bottomToolBar addSubview:_originalPhotoButton];
    [bottomToolBar addSubview:_doneButton];
    [bottomToolBar addSubview:_numberImageView];
    [bottomToolBar addSubview:_numberLabel];
    [bottomToolBar addSubview:divide];
    [self.view addSubview:bottomToolBar];
}

#pragma mark - Click Event
- (void)editButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSArray *models = [imagePickerVc.selectedModels copy];
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:models index:0 excludeVideo:YES];
    LFPhotoEdittingController *photoEdittingVC = [[LFPhotoEdittingController alloc] init];
    
    /** 抽取第一个对象 */
    LFAsset *model = models.firstObject;
    /** 获取缓存编辑对象 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit) {
        photoEdittingVC.photoEdit = photoEdit;
    } else if (model.previewImage) { /** 读取自定义图片 */
        photoEdittingVC.editImage = model.previewImage;
    } else {
        /** 获取对应的图片 */
        [[LFAssetManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            photoEdittingVC.editImage = photo;
        }];
    }
    [self pushPhotoPrevireViewController:photoPreviewVc photoEdittingViewController:photoEdittingVC];
}

- (void)previewButtonClick {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    NSArray *models = [imagePickerVc.selectedModels copy];
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:models index:0 excludeVideo:YES];
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    imagePickerVc.isSelectOriginalPhoto = _originalPhotoButton.isSelected;;
    if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
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
    NSMutableArray *thumbnailImages = [NSMutableArray array];
    NSMutableArray *originalImages = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *infoArr = [NSMutableArray array];
    
    
    for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) { [assets addObject:@1];[infoArr addObject:@1]; [thumbnailImages addObject:@1];[originalImages addObject:@1];}
    
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_globalQueue_async_safe(^{
        
        if (imagePickerVc.selectedModels.count) {
            void (^photosComplete)(UIImage *, UIImage *, NSDictionary *, NSInteger, id) = ^(UIImage *thumbnail, UIImage *source, NSDictionary *info, NSInteger index, id asset) {
                if (thumbnail) [thumbnailImages replaceObjectAtIndex:index withObject:thumbnail];
                if (source) [originalImages replaceObjectAtIndex:index withObject:source];
                if (info) [infoArr replaceObjectAtIndex:index withObject:info];
                if (asset) [assets replaceObjectAtIndex:index withObject:asset];
                
                if ([assets containsObject:@1]) return;
                
                dispatch_main_async_safe(^{
                    if (weakSelf == nil) return ;
                    [imagePickerVc hideProgressHUD];
                    if (imagePickerVc.autoDismiss) {
                        [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                            [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                        }];
                    } else {
                        [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                    }
                });
            };
            
            
            for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) {
                LFAsset *model = imagePickerVc.selectedModels[i];
                LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
                if (photoEdit) {
                    [[LFPhotoEditManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                        /** 编辑图片保存到相册 */
                        [[LFAssetManager manager] saveImageToCustomPhotosAlbumWithTitle:nil image:source complete:nil];
                        photosComplete(thumbnail, source, info, i, model.asset);
                    }];
                } else {
                    if (imagePickerVc.isSelectOriginalPhoto) {
                        [[LFAssetManager manager] getOriginPhotoWithAsset:model.asset completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                            photosComplete(thumbnail, source, info, i, model.asset);
                        }];
                    } else {
                        [[LFAssetManager manager] getPreviewPhotoWithAsset:model.asset completion:^(UIImage *thumbnail, UIImage *source, NSDictionary *info) {
                            photosComplete(thumbnail, source, info, i, model.asset);
                        }];
                    }
                }
            }
        } else {
            dispatch_main_async_safe(^{
                [imagePickerVc hideProgressHUD];
                if (imagePickerVc.autoDismiss) {
                    [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                        [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                    }];
                } else {
                    [weakSelf callDelegateMethodWithAssets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
                }
            });
        }
    });
    
}

- (void)callDelegateMethodWithAssets:(NSArray *)assets thumbnailImages:(NSArray *)thumbnailImages originalImages:(NSArray *)originalImages infoArr:(NSArray *)infoArr {
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    id <LFImagePickerControllerDelegate> pickerDelegate = (id <LFImagePickerControllerDelegate>)imagePickerVc.pickerDelegate;
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingAssets:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingAssets:assets];
    } else if (imagePickerVc.didFinishPickingPhotosHandle) {
        imagePickerVc.didFinishPickingPhotosHandle(assets);
    }
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingAssets:infos:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingAssets:assets infos:infoArr];
    } else if (imagePickerVc.didFinishPickingPhotosWithInfosHandle) {
        imagePickerVc.didFinishPickingPhotosWithInfosHandle(assets,infoArr);
    }

    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingThumbnailImages:originalImages:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingThumbnailImages:thumbnailImages originalImages:originalImages];
    } else if (imagePickerVc.didFinishPickingImagesHandle) {
        imagePickerVc.didFinishPickingImagesHandle(thumbnailImages, originalImages);
    }
    
    if ([pickerDelegate respondsToSelector:@selector(lf_imagePickerController:didFinishPickingThumbnailImages:originalImages:infos:)]) {
        [pickerDelegate lf_imagePickerController:imagePickerVc didFinishPickingThumbnailImages:thumbnailImages originalImages:originalImages infos:infoArr];
    } else if (imagePickerVc.didFinishPickingImagesWithInfosHandle) {
        imagePickerVc.didFinishPickingImagesWithInfosHandle(thumbnailImages, originalImages, infoArr);
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
    LFAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCell" forIndexPath:indexPath];
    cell.photoDefImageName = imagePickerVc.photoDefImageName;
    cell.photoSelImageName = imagePickerVc.photoSelImageName;
    NSInteger index = indexPath.row - 1;
    if (imagePickerVc.sortAscendingByCreateDate || !_showTakePhotoBtn) {
        index = indexPath.row;
    }
    LFAsset *model = _models[index];
    cell.model = model;
    cell.onlySelected = !imagePickerVc.allowPreview;
    cell.noSelected = model.type == LFAssetMediaTypeVideo && imagePickerVc.selectedModels.count;
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected, LFAsset *cellModel) {
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
            
            /** 没有选择需要刷新视频恢复显示 */
            if (imagePickerVc.selectedModels.count == 0) {
                [weakSelf refreshVideoCell];
            }
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePickerVc.selectedModels.count < imagePickerVc.maxImagesCount) {
                cellModel.isSelected = YES;
                [imagePickerVc.selectedModels addObject:cellModel];
                [weakSelf refreshBottomToolBarStatus];
                
                /** 首次有选择需要刷新视频隐藏显示 */
                if (imagePickerVc.selectedModels.count == 1) {
                    [weakSelf refreshVideoCell];
                }
            } else {
                NSString *title = [NSString stringWithFormat:@"你最多只能选择%zd张照片", imagePickerVc.maxImagesCount];
                [imagePickerVc showAlertWithTitle:title];
            }
        }
        [UIView showOscillatoryAnimationWithLayer:weakLayer type:OscillatoryAnimationToSmaller];
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
    LFAsset *model = _models[index];
    if (model.type == LFAssetMediaTypeVideo) {
        if (imagePickerVc.selectedModels.count > 0) {
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:@"选择照片时不能选择视频"];
        } else {
            LFVideoPlayerController *videoPlayerVc = [[LFVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            [self.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else {
        LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] initWithModels:[_models copy] index:index excludeVideo:YES];
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

#pragma mark - Private Method

- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if ((authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied) && iOS7Later) {
        // 无权限 做一个友好的提示
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *message = [NSString stringWithFormat:@"请在iPhone的\"设置-隐私-相机\"中允许%@访问相机",appName];
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"无法使用相机" message:message cancelButtonTitle:@"取消" otherButtonTitles:@"设置" block:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 1) { // 去设置界面，开启相机访问权限
                if (iOS8Later) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                } else {
                    NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"];
                    if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
                        [[UIApplication sharedApplication] openURL:privacyUrl];
                    } else {
                        NSString *message = @"无法跳转到隐私设置页面，请手动前往设置页面，谢谢";
                        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"抱歉" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                        [alert show];
                    }
                }
            }
        }];
        
        
        [alert show];
    } else { // 调用相机
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            if (self.takePhotoHandle) self.takePhotoHandle();
        } else {
            NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        }
    }
}

- (void)refreshVideoCell
{
    NSMutableArray <NSIndexPath *>*indexPaths = [NSMutableArray array];
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(LFAssetCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cell isKindOfClass:[LFAssetCell class]] && cell.model.type == LFAssetMediaTypeVideo) {
            NSInteger index = [_models indexOfObject:cell.model];
            LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
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
    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    
    _numberImageView.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLabel.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePickerVc.selectedModels.count];
    
    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _originalPhotoButton.selected = (imagePickerVc.isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLabel.hidden = (!_originalPhotoButton.isSelected);
    if (imagePickerVc.isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc {
    
    [self pushPhotoPrevireViewController:photoPreviewVc photoEdittingViewController:nil];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc photoEdittingViewController:(LFPhotoEdittingController *)photoEdittingVC {
    
    /** 关联代理 */
    photoEdittingVC.delegate = (id)photoPreviewVc;
    
    __weak typeof(self) weakSelf = self;
    [photoPreviewVc setBackButtonClickBlock:^{
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^{
        [weakSelf doneButtonClick];
    }];
    
    if (photoEdittingVC) {
        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
        [viewControllers addObject:photoPreviewVc];
        [viewControllers addObject:photoEdittingVC];
        [self.navigationController setViewControllers:viewControllers animated:YES];
    } else {
        [self.navigationController pushViewController:photoPreviewVc animated:YES];
    }
}


- (void)getSelectedPhotoBytes {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [[LFAssetManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        _originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
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
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    for (LFAsset *model in imagePickerVc.selectedModels) {
        if (model.asset) {
            [selectedAssets addObject:model.asset];
        }
    }
    if (selectedAssets.count) {        
        for (LFAsset *model in _models) {
            model.isSelected = NO;
            if ([[LFAssetManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
                model.isSelected = YES;
            }
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
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

@end
