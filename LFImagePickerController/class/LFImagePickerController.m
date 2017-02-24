//
//  LFImagePickerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFImagePickerController.h"
#import "LFImagePickerHeader.h"
#import "LFAssetManager.h"
#import "LFAssetManager+Authorization.h"
#import "LFPhotoEditManager.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"

#import "LFAlbumPickerController.h"
#import "LFPhotoPickerController.h"
#import "LFPhotoPreviewController.h"

@interface LFImagePickerController ()
{
    NSTimer *_timer;
    UILabel *_tipLabel;
    UIButton *_settingBtn;
    BOOL _pushPhotoPickerVc;
    BOOL _didPushPhotoPickerVc;
}

/** 多少列 默认4（2～6） */
@property (nonatomic, assign) NSInteger columnNumber;
@end

@implementation LFImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![[LFAssetManager manager] authorizationStatusAuthorized]) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.frame = CGRectMake(8, 120, self.view.width - 16, 60);
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
        _tipLabel.font = [UIFont systemFontOfSize:16];
        _tipLabel.textColor = [UIColor blackColor];
        NSString *appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleDisplayName"];
        if (!appName) appName = [[NSBundle mainBundle].infoDictionary valueForKey:@"CFBundleName"];
        NSString *tipText = [NSString stringWithFormat:@"请在iPhone的\"设置-隐私-照片\"选项中，\r允许%@访问你的手机相册",appName];
        _tipLabel.text = tipText;
        [self.view addSubview:_tipLabel];
        
        _settingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        [_settingBtn setTitle:self.settingBtnTitleStr forState:UIControlStateNormal];
        _settingBtn.frame = CGRectMake(0, 180, self.view.width, 44);
        _settingBtn.titleLabel.font = [UIFont systemFontOfSize:18];
        [_settingBtn addTarget:self action:@selector(settingBtnClick) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_settingBtn];
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:YES];
    } else {
        [self pushPhotoPickerVc];
    }
}

- (void)dealloc
{
    /** 清空单例 */
    [LFAssetManager free];
    [LFPhotoEditManager free];
}

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<LFImagePickerControllerDelegate>)delegate {
    return [self initWithMaxImagesCount:maxImagesCount columnNumber:4 delegate:delegate pushPhotoPickerVc:YES];
}

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate {
    return [self initWithMaxImagesCount:maxImagesCount columnNumber:columnNumber delegate:delegate pushPhotoPickerVc:YES];
}

- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate pushPhotoPickerVc:(BOOL)pushPhotoPickerVc {
    _pushPhotoPickerVc = pushPhotoPickerVc;
    self = [super init];
    if (self) {
        self.maxImagesCount = maxImagesCount > 0 ? maxImagesCount : 9; // Default is 9 / 默认最大可选9张图片
        self.pickerDelegate = delegate;
        self.selectedModels = [NSMutableArray array];
        
        // Allow user picking original photo and video, you also can set No after this method
        // 默认准许用户选择原图和视频, 你也可以在这个方法后置为NO
        [self defaultConfig];
        self.columnNumber = columnNumber;
    }
    return self;
}

/// This init method just for previewing photos / 用这个初始化方法以预览图片
- (instancetype)initWithSelectedAssets:(NSMutableArray /**<PHAsset/ALAsset *>*/*)selectedAssets index:(NSInteger)index excludeVideo:(BOOL)excludeVideo complete:(void (^)(NSArray *assets))complete
{
    NSMutableArray *models = [@[] mutableCopy];
    for (id asset in selectedAssets) {
        LFAssetMediaType type = [[LFAssetManager manager] mediaTypeWithModel:asset];
        LFAsset *model = [[LFAsset alloc] initWithAsset:asset type:type];
        [models addObject:model];
    }
    LFPhotoPreviewController *previewVc = [[LFPhotoPreviewController alloc] initWithModels:models index:index excludeVideo:excludeVideo];
    self = [super initWithRootViewController:previewVc];
    if (self) {
        [self defaultConfig];
        __weak typeof(self) weakSelf = self;
        [previewVc setDoneButtonClickBlock:^{
            
            NSMutableArray *assets = [@[] mutableCopy];
            for (LFAsset *model in weakSelf.selectedModels) {
                if (model.asset) {
                    [assets addObject:model.asset];
                }
            }
            if (weakSelf.autoDismiss) {
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    if (complete) complete(assets);
                }];
            } else {
                if (complete) complete(assets);
            }
        }];
    }
    return self;
}

- (instancetype)initWithSelectedPhotos:(NSArray <UIImage *>*)selectedPhotos index:(NSInteger)index complete:(void (^)(NSArray *photos))complete
{
    LFPhotoPreviewController *previewVc = [[LFPhotoPreviewController alloc] initWithPhotos:selectedPhotos index:index];
    self = [super initWithRootViewController:previewVc];
    if (self) {
        [self defaultConfig];
        __weak typeof(self) weakSelf = self;
        [previewVc setDoneButtonClickBlock:^{
            
            NSMutableArray *photos = [@[] mutableCopy];
            for (LFAsset *model in weakSelf.selectedModels) {
                if (model.previewImage) {
                    [photos addObject:model.previewImage];
                }
            }
            if (weakSelf.autoDismiss) {
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    if (complete) complete(photos);
                }];
            } else {
                if (complete) complete(photos);
            }
        }];

    }
    return self;
}

- (void)defaultConfig
{
    self.allowPickingOriginalPhoto = YES;
    self.allowPickingVideo = YES;
    self.allowPickingImage = YES;
    self.allowTakePicture = YES;
    self.allowPreview = YES;
    self.allowEditting = YES;
    self.sortAscendingByCreateDate = YES;
    self.autoDismiss = YES;
}

- (void)observeAuthrizationStatusChange {
    if ([[LFAssetManager manager] authorizationStatusAuthorized]) {
        [_tipLabel removeFromSuperview];
        [_settingBtn removeFromSuperview];
        [_timer invalidate];
        _timer = nil;
        [self pushPhotoPickerVc];
    }
}

- (void)pushPhotoPickerVc {
    _didPushPhotoPickerVc = NO;
    if (!_didPushPhotoPickerVc) {
        LFAlbumPickerController *albumPickerVc = [[LFAlbumPickerController alloc] init];
        if (self.allowPickingImage) {
            albumPickerVc.navigationItem.title = @"相册";
        } else if (self.allowPickingVideo) {
            albumPickerVc.navigationItem.title = @"视频";
        }
        albumPickerVc.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonClick)];
        if (_pushPhotoPickerVc) {
            LFPhotoPickerController *photoPickerVc = [[LFPhotoPickerController alloc] init];
            [self setViewControllers:@[albumPickerVc, photoPickerVc] animated:YES];
        } else {
            [self setViewControllers:@[albumPickerVc] animated:YES];
        }

        _didPushPhotoPickerVc = YES;
    }
}

- (void)setColumnNumber:(NSInteger)columnNumber {
    _columnNumber = columnNumber;
    if (columnNumber <= 2) {
        _columnNumber = 2;
    } else if (columnNumber >= 6) {
        _columnNumber = 6;
    }
}

- (void)setSelectedAssets:(NSMutableArray *)selectedAssets {
    
    _selectedModels = [NSMutableArray array];
    for (id asset in selectedAssets) {
        LFAssetMediaType type = [[LFAssetManager manager] mediaTypeWithModel:asset];
        LFAsset *model = [[LFAsset alloc] initWithAsset:asset type:type];
        model.isSelected = YES;
        [_selectedModels addObject:model];
    }
}

- (void)settingBtnClick {
    if (iOS8Later) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=PHOTOS"];
        if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
            [[UIApplication sharedApplication] openURL:privacyUrl];
        } else {
            NSString *message = @"无法跳转到隐私设置页面，请手动前往设置页面，谢谢";
            UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"抱歉" message:message delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [alert show];
        }
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (iOS7Later) {
        viewController.automaticallyAdjustsScrollViewInsets = NO;
    }
    if (_timer) { [_timer invalidate]; _timer = nil;}
    [super pushViewController:viewController animated:animated];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers animated:(BOOL)animated
{
    if (iOS7Later) {
        for (UIViewController *controller in viewControllers) {
            controller.automaticallyAdjustsScrollViewInsets = NO;
        }
    }
    if (_timer) { [_timer invalidate]; _timer = nil;}
    [super setViewControllers:viewControllers animated:animated];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Public

- (void)cancelButtonClick {
    if (self.autoDismiss) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self callDelegateMethod];
        }];
    } else {
        [self callDelegateMethod];
    }
}

- (void)callDelegateMethod {
    if ([self.pickerDelegate respondsToSelector:@selector(lf_imagePickerControllerDidCancel:)]) {
        [self.pickerDelegate lf_imagePickerControllerDidCancel:self];
    } else if (self.imagePickerControllerDidCancelHandle) {
        self.imagePickerControllerDidCancelHandle();
    }
}

@end
