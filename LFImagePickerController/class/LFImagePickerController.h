//
//  LFImagePickerController.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFLayoutPickerController.h"

@class LFAsset;
@protocol LFImagePickerControllerDelegate;
@interface LFImagePickerController : LFLayoutPickerController

/// Use this init method / 用这个初始化方法
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount delegate:(id<LFImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate;
- (instancetype)initWithMaxImagesCount:(NSInteger)maxImagesCount columnNumber:(NSInteger)columnNumber delegate:(id<LFImagePickerControllerDelegate>)delegate pushPhotoPickerVc:(BOOL)pushPhotoPickerVc;
/// This init method just for previewing photos,pickerDelegate = self; / 用这个初始化方法以预览图片,pickerDelegate = self;
- (instancetype)initWithSelectedAssets:(NSArray /**<PHAsset/ALAsset *>*/*)selectedAssets index:(NSInteger)index excludeVideo:(BOOL)excludeVideo;
/// This init method just for previewing photos, complete block call back  (invalid delegate)/ 用这个初始化方法以预览图片 complete => 完成后返回全新数组 （代理无效）
- (instancetype)initWithSelectedPhotos:(NSArray <UIImage *>*)selectedPhotos index:(NSInteger)index complete:(void (^)(NSArray <UIImage *>* photos))complete;

/** 预览模式 */
@property (nonatomic, readonly) BOOL isPreview;

/** 每行的数量 */
@property (nonatomic, readonly) NSInteger columnNumber;

/// Default is 9 / 默认最大可选9张图片
@property (nonatomic, assign) NSInteger maxImagesCount;

/// The minimum count photos user must pick, Default is 0
/// 最小照片必选张数,默认是0
@property (nonatomic, assign) NSInteger minImagesCount;

/// Sort photos ascending by creationDate，Default is YES
/// 对照片排序，按创建时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
@property (nonatomic, assign) BOOL sortAscendingByCreateDate;

/// Default is YES, if set NO, the original photo button will hide. user can't picking original photo.
/// 默认为YES，如果设置为NO,原图按钮将隐藏，用户不能选择发送原图
@property (nonatomic, assign) BOOL allowPickingOriginalPhoto;

/// Default is YES, if set NO, user can't picking video.
/// 默认为YES，如果设置为NO,用户将不能选择视频
@property (nonatomic, assign) BOOL allowPickingVideo;

/// Default is YES, if set NO, user can't picking image.
/// 默认为YES，如果设置为NO,用户将不能选择发送图片
@property(nonatomic, assign) BOOL allowPickingImage;

/// Default is YES, if set NO, user can't take picture.
/// 默认为YES，如果设置为NO,拍照按钮将隐藏,用户将不能选择照片
@property(nonatomic, assign) BOOL allowTakePicture;

/// Default is YES, if set NO, user can't preview photo.
/// 默认为YES，如果设置为NO,预览按钮将隐藏,用户将不能去预览照片
@property (nonatomic, assign) BOOL allowPreview;

/// Default is YES, if set NO, user can't editting photo.
/// 默认为YES，如果设置为NO,编辑按钮将隐藏,用户将不能去编辑照片
@property (nonatomic, assign) BOOL allowEditting;

/// Default is YES, if set NO, the picker don't dismiss itself.
/// 默认为YES，如果设置为NO, 选择器将不会自己dismiss
@property(nonatomic, assign) BOOL autoDismiss;

/// The photos user have selected
/// 用户选中过的图片数组
@property (nonatomic, strong) NSMutableArray<LFAsset *> *selectedModels;
@property (nonatomic, setter=setSelectedAssets:) NSArray /**<PHAsset/ALAsset/UIImage *>*/*selectedAssets;
/** 是否选择原图 */
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;

/// Public Method
- (void)cancelButtonClick;

/** block回调，具体使用见LFImagePickerControllerDelegate代理描述 */
@property (nonatomic, copy) void (^imagePickerControllerDidCancelHandle)();
/** 图片 */
@property (nonatomic, copy) void (^didFinishPickingPhotosHandle)(NSArray *assets);
@property (nonatomic, copy) void (^didFinishPickingPhotosWithInfosHandle)(NSArray *assets,NSArray<NSDictionary *> *infos);
@property (nonatomic, copy) void (^didFinishPickingImagesHandle)(NSArray<UIImage *> *thumbnailImages,NSArray<UIImage *> *originalImages);
@property (nonatomic, copy) void (^didFinishPickingImagesWithInfosHandle)(NSArray<UIImage *> *thumbnailImages,NSArray<UIImage *> *originalImages, NSArray<NSDictionary *> *infos);
/** 视频 */
@property (nonatomic, copy) void (^didFinishPickingVideoHandle)(UIImage *coverImage,id asset);
@property (nonatomic, copy) void (^didFinishPickingVideoWithThumbnailAndPathHandle)(UIImage *coverImage, NSString *path);


/** 代理 */
@property (nonatomic, weak) id<LFImagePickerControllerDelegate> pickerDelegate;

@end


@protocol LFImagePickerControllerDelegate <NSObject> /** 每个代理方法都有对应的block回调 */
@optional

- (void)lf_imagePickerControllerDidCancel:(LFImagePickerController *)picker;
//如果系统版本大于iOS8，asset是PHAsset类的对象，否则是ALAsset类的对象

/// ======== 图片回调 ========

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param assets 相片对象
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets;

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param assets 相片对象
 @param infos 相片信息
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets infos:(NSArray<NSDictionary *> *)infos;

/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset方向调整为向上，生成2张图片（压缩的缩略图10k左右；原图会根据UI是否勾选原图处理，没有勾选则压缩成标清图）
 
 @param picker 选择器
 @param thumbnailImages 缩略图
 @param originalImages 原图
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingThumbnailImages:(NSArray<UIImage *> *)thumbnailImages originalImages:(NSArray<UIImage *> *)originalImages;
/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset方向调整为向上，生成2张图片（压缩的缩略图10k左右；原图会根据UI是否勾选原图处理，没有勾选则压缩成标清图），附带（原图/标清图）的部分信息，
 
 @param picker 选择器
 @param thumbnailImages 缩略图
 @param originalImages 原图
 @param infos 图片信息
 kImageInfoFileName 图片名称
 kImageInfoFileSize 图片大小［长、宽］
 kImageInfoFileByte 图片大小［字节］
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingThumbnailImages:(NSArray<UIImage *> *)thumbnailImages originalImages:(NSArray<UIImage *> *)originalImages infos:(NSArray<NSDictionary *> *)infos;

/// ======== 视频回调 ========

/**
 当选择器点击完成的时候，会执行回调

 @param picker 选择器
 @param coverImage 视频第一帧图片
 @param asset 相片对象
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset;
/**
 当选择器点击完成的时候，会执行回调
 👍傻瓜接口：将asset提取到缓存空间并压缩视频保存，回调路径可复制到自定义目录；若需要删除缓存，缓存路径由LFAssetManager提供
 
 @param picker 选择器
 @param coverImage 视频第一帧图片
 @param path 视频路径mp4
 */
- (void)lf_imagePickerController:(LFImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage path:(NSString *)path;

@end
