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
#import "LFVideoPlayerController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "UIAlertView+LF_Block.h"

#import "LFAlbum.h"
#import "LFAsset.h"
#import "LFAssetCell.h"
#import "LFAssetManager+Authorization.h"

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
    
    UIButton *_previewButton;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    BOOL _shouldScrollToBottom;
    BOOL _showTakePhotoBtn;
}
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) LFCollectionView *collectionView;

@end

static CGSize AssetGridThumbnailSize;

@implementation LFPhotoPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    _isSelectOriginalPhoto = imagePickerVc.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = _model.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:imagePickerVc.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:imagePickerVc action:@selector(cancelButtonClick)];
    _showTakePhotoBtn = (([[LFAssetManager manager] isCameraRollAlbum:_model.name]) && imagePickerVc.allowTakePicture);
    
    if (self.model) {
        if (!imagePickerVc.sortAscendingByModificationDate && !iOS8Later) {
            [[LFAssetManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage fetchLimit:0 ascending:imagePickerVc.sortAscendingByModificationDate completion:^(NSArray<LFAsset *> *models) {
                _models = [NSMutableArray arrayWithArray:models];
                [self initSubviews];
            }];
        } else {
            _models = [NSMutableArray arrayWithArray:_model.models];
            [self initSubviews];
        }
    } else {
        /** 没有相片 */
    }
}

- (void)initSubviews {
    [self checkSelectedModels];
    [self configCollectionView];
    [self configBottomToolBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    if (self.backButtonClickHandle) {
        self.backButtonClickHandle(_model);
    }
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)configCollectionView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = 5;
    CGFloat itemWH = (self.view.width - (self.columnNumber + 1) * margin) / self.columnNumber;
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
    
    _collectionView = [[LFCollectionView alloc] initWithFrame:CGRectMake(0, top, self.view.width, collectionViewHeight) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    _collectionView.contentInset = UIEdgeInsetsMake(margin, margin, margin, margin);
    
    if (_showTakePhotoBtn && imagePickerVc.allowTakePicture ) {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + self.columnNumber) / self.columnNumber) * self.view.width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.width, ((_model.count + self.columnNumber - 1) / self.columnNumber) * self.view.width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[LFAssetCell class] forCellWithReuseIdentifier:@"LFAssetCell"];
    [_collectionView registerClass:[LFAssetCameraCell class] forCellWithReuseIdentifier:@"LFAssetCameraCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollCollectionViewToBottom];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = 2.0;
    if ([UIScreen mainScreen].bounds.size.width > 600) {
        scale = 1.0;
    }
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

- (void)configBottomToolBar {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    CGFloat yOffset = 0;
    if (self.navigationController.navigationBar.isTranslucent) {
        yOffset = self.view.height - 50;
    } else {
        CGFloat navigationHeight = 44;
        if (iOS7Later) navigationHeight += 20;
        yOffset = self.view.height - 50 - navigationHeight;
    }
    
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, self.view.width, 50)];
    CGFloat rgb = 253 / 255.0;
    bottomToolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    CGFloat previewWidth = [imagePickerVc.previewBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]} context:nil].size.width + 2;
    if (!imagePickerVc.allowPreview) {
        previewWidth = 0.0;
    }
    _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _previewButton.frame = CGRectMake(10, 3, previewWidth, 44);
    _previewButton.width = previewWidth;
    [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateNormal];
    [_previewButton setTitle:imagePickerVc.previewBtnTitleStr forState:UIControlStateDisabled];
    [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _previewButton.enabled = imagePickerVc.selectedModels.count;
    
    if (imagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [imagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.frame = CGRectMake(CGRectGetMaxX(_previewButton.frame), self.view.height - 50, fullImageWidth + 56, 50);
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:imagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:[UIImage imageNamed:imagePickerVc.photoOriginDefImageName] forState:UIControlStateNormal];
        [_originalPhotoButton setImage:[UIImage imageNamed:imagePickerVc.photoOriginSelImageName] forState:UIControlStateSelected];
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 46, 0, 80, 50);
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:16];
        _originalPhotoLabel.textColor = [UIColor blackColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
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
    
    _numberImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imagePickerVc.photoNumberIconImageName]];
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
    
    [bottomToolBar addSubview:divide];
    [bottomToolBar addSubview:_previewButton];
    [bottomToolBar addSubview:_doneButton];
    [bottomToolBar addSubview:_numberImageView];
    [bottomToolBar addSubview:_numberLabel];
    [self.view addSubview:bottomToolBar];
    [self.view addSubview:_originalPhotoButton];
    [_originalPhotoButton addSubview:_originalPhotoLabel];
}

#pragma mark - Click Event

- (void)previewButtonClick {
    LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] init];
    photoPreviewVc.models = _models;
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
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
    NSMutableArray *photos = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *infoArr = [NSMutableArray array];
    
    for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; [thumbnailImages addObject:@1];[originalImages addObject:@1];}
    
    
    __weak typeof(self) weakSelf = self;
    
    void (^photosComplete)(UIImage *, UIImage *, NSDictionary *, NSInteger, id) = ^(UIImage *thumbnail, UIImage *source, NSDictionary *info, NSInteger index, id asset) {
        if (thumbnail) [thumbnailImages replaceObjectAtIndex:index withObject:thumbnail];
        if (source) [originalImages replaceObjectAtIndex:index withObject:source];
        if (source) {
            CGSize size = CGSizeMake(imagePickerVc.photoWidth, (int)(imagePickerVc.photoWidth * source.size.height / source.size.width));
            UIImage *photo = [weakSelf scaleImage:source toSize:size];
            if (photo) {
                [photos replaceObjectAtIndex:index withObject:photo];
            } else {
                [photos replaceObjectAtIndex:index withObject:source];
            }
        }
        if (info) [infoArr replaceObjectAtIndex:index withObject:info];
        if (asset) [assets replaceObjectAtIndex:index withObject:asset];
        
        if ([photos containsObject:@1]) return;
        
        
        [imagePickerVc hideProgressHUD];
        if (imagePickerVc.autoDismiss) {
            [imagePickerVc dismissViewControllerAnimated:YES completion:^{
                [weakSelf callDelegateMethodWithPhotos:photos assets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
            }];
        } else {
            [weakSelf callDelegateMethodWithPhotos:photos assets:assets thumbnailImages:thumbnailImages originalImages:originalImages infoArr:infoArr];
        }
    };
    
    
    for (NSInteger i = 0; i < imagePickerVc.selectedModels.count; i++) {
        LFAsset *model = imagePickerVc.selectedModels[i];
        if ([[self valueForKey:@"isSelectOriginalPhoto"] boolValue]) {
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

- (void)callDelegateMethodWithPhotos:(NSArray *)photos assets:(NSArray *)assets thumbnailImages:(NSArray *)thumbnailImages originalImages:(NSArray *)originalImages infoArr:(NSArray *)infoArr {
    
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
    if (((imagePickerVc.sortAscendingByModificationDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByModificationDate && indexPath.row == 0)) && _showTakePhotoBtn) {
        LFAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCameraCell" forIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:imagePickerVc.takePictureImageName];
        return cell;
    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    LFAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LFAssetCell" forIndexPath:indexPath];
    cell.photoDefImageName = imagePickerVc.photoDefImageName;
    cell.photoSelImageName = imagePickerVc.photoSelImageName;
    LFAsset *model;
    if (imagePickerVc.sortAscendingByModificationDate || !_showTakePhotoBtn) {
        model = _models[indexPath.row];
    } else {
        model = _models[indexPath.row - 1];
    }
    cell.model = model;
    
    if (!imagePickerVc.allowPreview) {
        cell.selectPhotoButton.frame = cell.bounds;
    }
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)weakSelf.navigationController;
        // 1. cancel select / 取消选择
        if (isSelected) {
            weakCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:imagePickerVc.selectedModels];
            for (LFAsset *model_item in selectedModels) {
                if ([[[LFAssetManager manager] getAssetIdentifier:model.asset] isEqualToString:[[LFAssetManager manager] getAssetIdentifier:model_item.asset]]) {
                    [imagePickerVc.selectedModels removeObject:model_item];
                    break;
                }
            }
            [weakSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (imagePickerVc.selectedModels.count < imagePickerVc.maxImagesCount) {
                weakCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [imagePickerVc.selectedModels addObject:model];
                [weakSelf refreshBottomToolBarStatus];
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
    if (((imagePickerVc.sortAscendingByModificationDate && indexPath.row >= _models.count) || (!imagePickerVc.sortAscendingByModificationDate && indexPath.row == 0)) && _showTakePhotoBtn)  {
        [self takePhoto]; return;
    }
    // preview phote or video / 预览照片或视频
    NSInteger index = indexPath.row;
    if (!imagePickerVc.sortAscendingByModificationDate && _showTakePhotoBtn) {
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
        LFPhotoPreviewController *photoPreviewVc = [[LFPhotoPreviewController alloc] init];
        photoPreviewVc.currentIndex = index;
        photoPreviewVc.models = _models;
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

- (void)refreshBottomToolBarStatus {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    
    _previewButton.enabled = imagePickerVc.selectedModels.count > 0;
    _doneButton.enabled = imagePickerVc.selectedModels.count;
    
    _numberImageView.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLabel.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",imagePickerVc.selectedModels.count];
    
    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLabel.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(LFPhotoPreviewController *)photoPreviewVc {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    [photoPreviewVc setBackButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    }];
    [photoPreviewVc setDoneButtonClickBlock:^(BOOL isSelectOriginalPhoto) {
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf doneButtonClick];
    }];
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [[LFAssetManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        _originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

/// Scale image / 缩放图片
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    if (image.size.width < size.width) {
        return image;
    }
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)scrollCollectionViewToBottom {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (_shouldScrollToBottom && _models.count > 0 && imagePickerVc.sortAscendingByModificationDate) {
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
    for (LFAsset *model in _models) {
        model.isSelected = NO;
        NSMutableArray *selectedAssets = [NSMutableArray array];
        LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
        for (LFAsset *model in imagePickerVc.selectedModels) {
            [selectedAssets addObject:model.asset];
        }
        if ([[LFAssetManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
            model.isSelected = YES;
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    //NSLog(@"TZPhotoPickerController dealloc");
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
