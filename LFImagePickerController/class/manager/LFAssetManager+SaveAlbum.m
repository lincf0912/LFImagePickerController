//
//  LFAssetManager+SaveAlbum.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/3/24.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager+SaveAlbum.h"
#import "LFAssetManager+Authorization.h"
#import "LFImagePickerHeader.h"

@implementation LFAssetManager (SaveAlbum)

#pragma mark - 创建相册
- (void)createCustomAlbumWithTitle:(NSString *)title complete:(void (^)(PHAssetCollection *result))complete faile:(void (^)(NSError *error))faile{
    if (title.length == 0) {
        if (complete) complete(nil);
    }else{
        dispatch_globalQueue_async_safe(^{
            // 是否存在相册 如果已经有了 就不再创建
            PHFetchResult <PHAssetCollection *> *results = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            BOOL haveHDRGroup = NO;
            NSError *error = nil;
            PHAssetCollection *createCollection = nil;
            for (PHAssetCollection *collection in results) {
                if ([collection.localizedTitle isEqualToString:title]) {
                    /** 已经存在了，不需要创建了 */
                    haveHDRGroup = YES;
                    createCollection = collection;
                    break;
                }
            }
            if (haveHDRGroup) {
                NSLog(@"已经存在了，不需要创建了");
                dispatch_main_async_safe(^{
                    if (complete) complete(createCollection);
                });
            }else{
                __block NSString *createdCustomAssetCollectionIdentifier = nil;
                /**
                 * 注意：这个方法只是告诉 photos 我要创建一个相册，并没有真的创建
                 *      必须等到 performChangesAndWait block 执行完毕后才会
                 *      真的创建相册。
                 */
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:title];
                    /**
                     * collectionChangeRequest 即使我们告诉 photos 要创建相册，但是此时还没有
                     * 创建相册，因此现在我们并不能拿到所创建的相册，我们的需求是：将图片保存到
                     * 自定义的相册中，因此我们需要拿到自己创建的相册，从头文件可以看出，collectionChangeRequest
                     * 中有一个占位相册，placeholderForCreatedAssetCollection ，这个占位相册
                     * 虽然不是我们所创建的，但是其 identifier 和我们所创建的自定义相册的 identifier
                     * 是相同的。所以想要拿到我们自定义的相册，必须保存这个 identifier，等 photos app
                     * 创建完成后通过 identifier 来拿到我们自定义的相册
                     */
                    createdCustomAssetCollectionIdentifier = collectionChangeRequest.placeholderForCreatedAssetCollection.localIdentifier;
                } error:&error];
                if (error) {
                    NSLog(@"创建了%@相册失败",title);
                    dispatch_main_async_safe(^{
                        if (faile) faile(error);
                    });
                }else{
                    /** 获取创建成功的相册 */
                    createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCustomAssetCollectionIdentifier] options:nil].firstObject;
                    NSLog(@"创建了%@相册成功",title);
                    dispatch_main_async_safe(^{
                        if (complete) complete(createCollection);
                    });
                }
            }
        });
    }
}


#pragma mark - 保存图片到自定义相册
- (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title image:(UIImage *)saveImage complete:(void (^)(id ,NSError *))complete{
    if ([self authorizationStatusAuthorized]) {
        if (iOS8Later) {
            [self createCustomAlbumWithTitle:title complete:^(PHAssetCollection *result) {
                [self saveToAlbumIOS8LaterWithImage:saveImage customAlbum:result completionBlock:^(PHAsset *asset) {
                    if (complete) complete(asset, nil);
                } failureBlock:^(NSError *error) {
                    if (complete) complete(nil, error);
                }];
            } faile:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
        }else{
            /** iOS7之前保存图片到自定义相册方法 */
            [self saveToAlbumIOS8EarlyWithData:saveImage customAlbumName:title completionBlock:^(ALAsset *asset) {
                if (complete) complete(asset, nil);
            } failureBlock:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
        }
    } else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"没有权限访问相册"}];
        if (complete) complete(nil, error);
    }
}

#pragma mark - iOS8之后保存相片到自定义相册
- (void)saveToAlbumIOS8LaterWithImage:(UIImage *)image
                          customAlbum:(PHAssetCollection *)customAlbum
                      completionBlock:(void(^)(PHAsset *asset))completionBlock
                         failureBlock:(void (^)(NSError *error))failureBlock
{
    dispatch_globalQueue_async_safe(^{
        __block NSError *error = nil;
        NSMutableArray *imageIds = [NSMutableArray array];
        PHAssetCollection *assetCollection = (PHAssetCollection *)customAlbum;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
            PHObjectPlaceholder *placeholder = req.placeholderForCreatedAsset;
            //记录本地标识，等待完成后取到相册中的图片对象
            [imageIds addObject:req.placeholderForCreatedAsset.localIdentifier];
            if (assetCollection) {
                PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                //            [request addAssets:@[placeholder]];
                //将最新保存的图片设置为封面
                [request insertAssets:@[placeholder] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            }
        } error:&error];
        
        if (error) {
            NSLog(@"保存失败");
            dispatch_main_async_safe(^{
                if (failureBlock) failureBlock(error);
            });
        } else {
            NSLog(@"保存成功");
            //成功后取相册中的图片对象
            __block PHAsset *imageAsset = nil;
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:imageIds options:nil];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                imageAsset = obj;
                *stop = YES;
                
            }];
            
            dispatch_main_async_safe(^{
                if (completionBlock) completionBlock(imageAsset);
            });
        }
    });
}

#pragma mark - iOS8之前保存相片/视频到自定义相册
- (void)saveToAlbumIOS8EarlyWithData:(id)data
                     customAlbumName:(NSString *)customAlbumName
                     completionBlock:(void (^)(ALAsset *asset))completionBlock
                        failureBlock:(void (^)(NSError *error))failureBlock
{
    
    ALAssetsLibrary *assetsLibrary = [self assetLibrary];
    /** 循环引用处理 */
    __weak ALAssetsLibrary *weakAssetsLibrary = assetsLibrary;
    
    /** 查找自定义相册并保存 */
    void (^AddAsset)(ALAsset *) = ^(ALAsset *asset) {
        [weakAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupLibrary usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:customAlbumName]) {
                NSLog(@"保存相片成功");
                [group addAsset:asset];
                if (completionBlock) {
                    completionBlock(asset);
                }
                *stop = YES;
            }
            /** done */
            else if (group == nil) {
                if (completionBlock) {
                    completionBlock(asset);
                }
            }
        } failureBlock:^(NSError *error) {
            if (failureBlock) {
                failureBlock(error);
            }
        }];
    };
    
    /** 最终处理保存结果 */
    void (^completeBlock)(NSURL *assetURL, NSError *error) = ^(NSURL *assetURL, NSError *error) {
        if (error) {
            failureBlock(error);
        } else {
            /** 获取当前保存图片的asset */
            [weakAssetsLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                if (customAlbumName.length) {
                    /** 添加自定义相册 */
                    [weakAssetsLibrary addAssetsGroupAlbumWithName:customAlbumName resultBlock:^(ALAssetsGroup *group) {
                        if (group) {
                            [group addAsset:asset];
                            NSLog(@"保存相片成功");
                            if (completionBlock) {
                                completionBlock(asset);
                            }
                        } else { /** 相册已存在 */
                            /** 找到已创建相册，保存图片 */
                            AddAsset(asset);
                        }
                    } failureBlock:^(NSError *error) {
                        NSLog(@"%@",error.localizedDescription);
                        /** 创建失败，直接回调图片 */
                        if (completionBlock) {
                            completionBlock(asset);
                        }
                    }];
                } else {
                    if (completionBlock) {
                        completionBlock(asset);
                    }
                }
            } failureBlock:^(NSError *error) {
                NSLog(@"%@",error.localizedDescription);
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        }
    };
    
    if ([data isKindOfClass:[UIImage class]]) { /** 图片 */
        UIImage *image = data;
        /** 保存图片到系统相册，因为系统的 album 相当于一个 music library, 而自己的相册相当于一个 playlist, 你的 album 所有的内容必须是链接到系统相册里的内容的. */
        [assetsLibrary writeImageToSavedPhotosAlbum:image.CGImage orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
            completeBlock(assetURL, error);
        }];
    } else if ([data isKindOfClass:[NSURL class]]) { /** 视频 */
        NSURL *videoURL = data;
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
            completeBlock(assetURL, error);
        }];
    }
}


#pragma mark - 保存视频到自定义相册
- (void)saveVideoToCustomPhotosAlbumWithTitle:(NSString *)title filePath:(NSString *)filePath complete:(void(^)(id asset, NSError *error))complete{
    if ([self authorizationStatusAuthorized]) {
        NSFileManager *fileManager = [NSFileManager new];
        if ([fileManager fileExistsAtPath:filePath]) {
            NSURL *url = [NSURL URLWithString:filePath];
            if (iOS8Later) {
                [self createCustomAlbumWithTitle:title complete:^(PHAssetCollection *result) {
                    [self saveToAlbumIOS8LaterWithVideoUR:url customAlbum:result completionBlock:^(PHAsset *asset) {
                        if (complete) complete(asset, nil);
                    } failureBlock:^(NSError *error) {
                        if (complete) complete(nil, error);
                    }];
                } faile:^(NSError *error) {
                    if (complete) complete(nil, error);
                }];
            } else {
                //注意这个方法不能保存视频到自定义相册，只能保存到系统相册。
                [self saveToAlbumIOS8EarlyWithData:url customAlbumName:title completionBlock:^(ALAsset *asset) {
                    if (complete) complete(asset, nil);
                } failureBlock:^(NSError *error) {
                    if (complete) complete(nil, error);
                }];
            }
        }
    } else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"没有权限访问相册"}];
        if (complete) complete(nil, error);
    }
}

#pragma mark iOS8之后保存视频到自定义相册
- (void)saveToAlbumIOS8LaterWithVideoUR:(NSURL *)videoURL
                            customAlbum:(PHAssetCollection *)customAlbum
                        completionBlock:(void(^)(PHAsset *asset))completionBlock
                           failureBlock:(void (^)(NSError *error))failureBlock
{
    dispatch_globalQueue_async_safe(^{
        __block NSError *error = nil;
        NSMutableArray *imageIds = [NSMutableArray array];
        PHAssetCollection *assetCollection = (PHAssetCollection *)customAlbum;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
            PHObjectPlaceholder *placeholder = req.placeholderForCreatedAsset;
            //记录本地标识，等待完成后取到相册中的图片对象
            [imageIds addObject:req.placeholderForCreatedAsset.localIdentifier];
            if (assetCollection) {
                PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                //            [request addAssets:@[placeholder]];
                //将最新保存的图片设置为封面
                [request insertAssets:@[placeholder] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            }
        } error:&error];
        
        if (error) {
            NSLog(@"保存失败:%@", error.localizedDescription);
            dispatch_main_async_safe(^{
                if (failureBlock) failureBlock(error);
            });
        } else {
            NSLog(@"保存成功");
            //成功后取相册中的图片对象
            __block PHAsset *imageAsset = nil;
            PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:imageIds options:nil];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                imageAsset = obj;
                *stop = YES;
                
            }];
            dispatch_main_async_safe(^{
                if (completionBlock) completionBlock(imageAsset);
            });
        }
    });
}

@end
