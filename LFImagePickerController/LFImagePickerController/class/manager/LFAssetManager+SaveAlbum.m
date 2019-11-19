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

#import "UIImage+LF_Format.h"

@implementation LFAssetManager (SaveAlbum)

#pragma mark - 创建相册
- (void)createCustomAlbumWithTitle:(NSString *)title complete:(void (^)(PHAssetCollection *result))complete faile:(void (^)(NSError *error))faile{
    if ([self authorizationStatusAuthorized]) {
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
                    NSLog(@"Already exists");
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
                        NSLog(@"Album Failed: %@",title);
                        dispatch_main_async_safe(^{
                            if (faile) faile(error);
                        });
                    }else{
                        if (createdCustomAssetCollectionIdentifier) {
                            /** 获取创建成功的相册 */
                            createCollection = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[createdCustomAssetCollectionIdentifier] options:nil].firstObject;
                            NSLog(@"Album Created: %@",title);
                            dispatch_main_async_safe(^{
                                if (complete) complete(createCollection);
                            });
                        } else {
                            NSLog(@"Album Failed: %@",title);
                            dispatch_main_async_safe(^{
                                if (faile) faile(error);
                            });
                        }
                    }
                }
            });
        }
    }
}


#pragma mark - 保存图片到自定义相册
- (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title images:(NSArray <UIImage *>*)images complete:(void (^)(NSArray <id /* PHAsset/ALAsset */>*assets,NSError *error))complete
{
    [self baseSaveImageToCustomPhotosAlbumWithTitle:title datas:images complete:complete];
}
- (void)saveImageToCustomPhotosAlbumWithTitle:(NSString *)title imageDatas:(NSArray <NSData *>*)imageDatas complete:(void (^)(NSArray <id /* PHAsset/ALAsset */>*assets ,NSError *error))complete
{
    [self baseSaveImageToCustomPhotosAlbumWithTitle:title datas:imageDatas complete:complete];
}
- (void)baseSaveImageToCustomPhotosAlbumWithTitle:(NSString *)title datas:(NSArray <id /* NSData/UIImage */>*)datas complete:(void (^)(NSArray <id /* PHAsset/ALAsset */>*assets ,NSError *error))complete
{
    if ([self authorizationStatusAuthorized]) {
        if (@available(iOS 8.0, *)){
            [self createCustomAlbumWithTitle:title complete:^(PHAssetCollection *result) {
                [self saveToAlbumIOS8LaterWithImages:datas customAlbum:result completionBlock:^(NSArray<PHAsset *> *assets) {
                    if (complete) complete(assets, nil);
                } failureBlock:^(NSError *error) {
                    if (complete) complete(nil, error);
                }];
            } faile:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
        }else{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
            /** iOS7之前保存图片到自定义相册方法 */
            [self saveToAlbumIOS7EarlyWithDatas:datas customAlbumName:title completionBlock:^(NSArray<ALAsset *> *assets) {
                if (complete) complete(assets, nil);
            } failureBlock:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
#endif
        }
    } else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSBundle lf_localizedStringForKey:@"_LFAssetManager_SaveAlbum_notpermissionError"]}];
        if (complete) complete(nil, error);
    }
}

#pragma mark - iOS8之后保存相片到自定义相册
- (void)saveToAlbumIOS8LaterWithImages:(NSArray <id /* NSData/UIImage */>*)datas
                           customAlbum:(PHAssetCollection *)customAlbum
                       completionBlock:(void(^)(NSArray <PHAsset *>*assets))completionBlock
                          failureBlock:(void (^)(NSError *error))failureBlock
{
    NSError *error = nil;
    __block NSMutableArray <NSString *>*createdAssetIds = [@[] mutableCopy];
    PHAssetCollection *assetCollection = (PHAssetCollection *)customAlbum;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        for (id data in datas) {
            PHAssetChangeRequest *req = nil;
            if ([data isKindOfClass:[NSData class]]) {
                if (@available(iOS 9.0, *)){
                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                    req = [PHAssetCreationRequest creationRequestForAsset];
                    [(PHAssetCreationRequest *)req addResourceWithType:PHAssetResourceTypePhoto data:data options:options];
                } else {
                    UIImage *image = [UIImage LF_imageWithImageData:data];
                    req = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
                }
            } else if ([data isKindOfClass:[UIImage class]]) {
                req = [PHAssetChangeRequest creationRequestForAssetFromImage:data];
            }
            PHObjectPlaceholder *placeholder = req.placeholderForCreatedAsset;
            //记录本地标识，等待完成后取到相册中的图片对象
            NSString *createdAssetId = placeholder.localIdentifier;
            if (createdAssetId) {
                [createdAssetIds addObject:createdAssetId];
            }
        }
    } error:&error];
    
    if (error) {
        NSLog(@"Save failed");
        dispatch_main_async_safe(^{
            if (failureBlock) failureBlock(error);
        });
    } else {
        NSError *nextError = nil;
        PHFetchResult <PHAsset *>*result = nil;
        if (createdAssetIds.count) {
            //成功后取相册中的图片对象
            result = [PHAsset fetchAssetsWithLocalIdentifiers:createdAssetIds options:nil];
            
            /** 保存到指定相册 */
            if (assetCollection) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                    //            [request addAssets:@[placeholder]];
                    //将最新保存的图片设置为封面
                    [request insertAssets:result atIndexes:[NSIndexSet indexSetWithIndex:0]];
                } error:&nextError];
            }
        }
        if (result == nil) {
            nextError = [NSError errorWithDomain:@"SaveToAlbumError" code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSBundle lf_localizedStringForKey:@"_LFAssetManager_SaveAlbum_saveVideoError"]}];
        }
        
        if (nextError) {
            NSLog(@"Save failed");
            dispatch_main_async_safe(^{
                if (failureBlock) failureBlock(nextError);
            });
        } else {
            NSLog(@"Saved successfully");
            NSMutableArray <PHAsset *>*assets = [@[] mutableCopy];
            [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [assets addObject:obj];
            }];
            dispatch_main_async_safe(^{
                if (completionBlock) completionBlock([assets copy]);
            });
        }
    }
    dispatch_globalQueue_async_safe(^{
    });
}

#pragma mark - iOS7之前保存相片/视频到自定义相册
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
- (void)saveToAlbumIOS7EarlyWithDatas:(NSArray <id /* NSData/UIImage/NSURL */>*)datas
                      customAlbumName:(NSString *)customAlbumName
                      completionBlock:(void (^)(NSArray <ALAsset *>*assets))completionBlock
                         failureBlock:(void (^)(NSError *error))failureBlock
{
    
    ALAssetsLibrary *assetsLibrary = [self assetLibrary];
    /** 循环引用处理 */
    __weak ALAssetsLibrary *weakAssetsLibrary = assetsLibrary;
    
    NSMutableArray <ALAsset *>*assets = [@[] mutableCopy];
    
    void (^completeAssets)(ALAsset *) = ^(ALAsset *asset) {
        [assets addObject:asset];
        if (assets.count == datas.count) {
            if (completionBlock) {
                completionBlock([assets copy]);
            }
        }
    };
    
    /** 查找自定义相册并保存 */
    void (^AddAsset)(ALAsset *) = ^(ALAsset *asset) {
        [weakAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupLibrary usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:customAlbumName]) {
                NSLog(@"Save photo successfully");
                [group addAsset:asset];
                completeAssets(asset);
                *stop = YES;
            }
            /** done */
            else if (group == nil) {
                completeAssets(asset);
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
                            NSLog(@"Save photo successfully");
                            completeAssets(asset);
                        } else { /** 相册已存在 */
                            /** 找到已创建相册，保存图片 */
                            AddAsset(asset);
                        }
                    } failureBlock:^(NSError *error) {
                        NSLog(@"%@",error.localizedDescription);
                        /** 创建失败，直接回调图片 */
                        completeAssets(asset);
                    }];
                } else {
                    completeAssets(asset);
                }
            } failureBlock:^(NSError *error) {
                NSLog(@"%@",error.localizedDescription);
                if (failureBlock) {
                    failureBlock(error);
                }
            }];
        }
    };
    
    for (id data in datas) {
        if ([data isKindOfClass:[NSData class]]) { /** 图片 */
            /** 保存图片到系统相册，因为系统的 album 相当于一个 music library, 而自己的相册相当于一个 playlist, 你的 album 所有的内容必须是链接到系统相册里的内容的. */
            [assetsLibrary writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                completeBlock(assetURL, error);
            }];
        } else if ([data isKindOfClass:[UIImage class]]) { /** 图片 */
            [assetsLibrary writeImageToSavedPhotosAlbum:[(UIImage *)data CGImage] orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
                completeBlock(assetURL, error);
            }];
        } else if ([data isKindOfClass:[NSURL class]]) { /** 视频 */
            [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:data completionBlock:^(NSURL *assetURL, NSError *error) {
                completeBlock(assetURL, error);
            }];
        }
    }
    
}
#endif


#pragma mark - Save the video to a custom album
- (void)saveVideoToCustomPhotosAlbumWithTitle:(NSString *)title videoURLs:(NSArray <NSURL *>*)videoURLs complete:(void(^)(NSArray <id /* PHAsset/ALAsset */>*assets, NSError *error))complete
{
    if ([self authorizationStatusAuthorized]) {
        if (@available(iOS 8.0, *)){
            [self createCustomAlbumWithTitle:title complete:^(PHAssetCollection *result) {
                [self saveToAlbumIOS8LaterWithVideoURLs:videoURLs customAlbum:result completionBlock:^(NSArray<PHAsset *> *assets) {
                    if (complete) complete(assets, nil);
                } failureBlock:^(NSError *error) {
                    if (complete) complete(nil, error);
                }];
            } faile:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
        } else {
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
            //注意这个方法不能保存视频到自定义相册，只能保存到系统相册。
            [self saveToAlbumIOS7EarlyWithDatas:videoURLs customAlbumName:title completionBlock:^(NSArray<ALAsset *> *assets) {
                if (complete) complete(assets, nil);
            } failureBlock:^(NSError *error) {
                if (complete) complete(nil, error);
            }];
#endif
        }
    } else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSBundle lf_localizedStringForKey:@"_LFAssetManager_SaveAlbum_notpermissionError"]}];
        if (complete) complete(nil, error);
    }
}

#pragma mark iOS8 After saving the video to a custom album
- (void)saveToAlbumIOS8LaterWithVideoURLs:(NSArray <NSURL *>*)videoURLs
                              customAlbum:(PHAssetCollection *)customAlbum
                          completionBlock:(void(^)(NSArray <PHAsset *>*assets))completionBlock
                             failureBlock:(void (^)(NSError *error))failureBlock
{
    dispatch_globalQueue_async_safe(^{
        NSError *error = nil;
        __block NSMutableArray <NSString *>*createdAssetIds = [@[] mutableCopy];
        PHAssetCollection *assetCollection = (PHAssetCollection *)customAlbum;
        [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            for (NSURL *videoURL in videoURLs) {
                PHAssetChangeRequest *req = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoURL];
                PHObjectPlaceholder *placeholder = req.placeholderForCreatedAsset;
                //记录本地标识，等待完成后取到相册中的图片对象
                NSString *createdAssetId = placeholder.localIdentifier;
                if (createdAssetId) {
                    [createdAssetIds addObject:createdAssetId];
                }
            }
            
        } error:&error];
        
        if (error) {
            NSLog(@"Save failed:%@", error.localizedDescription);
            dispatch_main_async_safe(^{
                if (failureBlock) failureBlock(error);
            });
        } else {
            NSError *nextError = nil;
            PHFetchResult <PHAsset *>*result = nil;
            if (createdAssetIds.count) {
                //成功后取相册中的图片对象
                result = [PHAsset fetchAssetsWithLocalIdentifiers:createdAssetIds options:nil];
                
                if (result && assetCollection) {
                    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                        PHAssetCollectionChangeRequest *request = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                        //            [request addAssets:@[placeholder]];
                        //将最新保存的图片设置为封面
                        [request insertAssets:result atIndexes:[NSIndexSet indexSetWithIndex:0]];
                    } error:&nextError];
                }
            }
            if (result == nil) {
                nextError = [NSError errorWithDomain:@"SaveToAlbumError" code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSBundle lf_localizedStringForKey:@"_LFAssetManager_SaveAlbum_saveVideoError"]}];
            }
            if (nextError) {
                NSLog(@"Save failed");
                dispatch_main_async_safe(^{
                    if (failureBlock) failureBlock(nextError);
                });
            } else {
                NSLog(@"Saved successfully");
                NSMutableArray <PHAsset *>*assets = [@[] mutableCopy];
                [result enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [assets addObject:obj];
                }];
                dispatch_main_async_safe(^{
                    if (completionBlock) completionBlock([assets copy]);
                });
            }
        }
    });
}

- (void)deleteAssets:(NSArray <id /* PHAsset/ALAsset */ > *)assets complete:(void (^)(NSError *error))complete
{
    if (@available(iOS 8.0, *)){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest deleteAssets:assets];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_main_async_safe(^{
                NSLog(@"deleteAssets Error: %@", error);
                if (complete) {
                    complete(error);
                }
            });
        }];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_0
    else {
        for (ALAsset *result in assets) {
            if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                [result setVideoAtPath:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_main_async_safe(^{
                        NSLog(@"asset url(%@) should be delete . Error:%@ ", assetURL, error);
                        if (complete) {
                            complete(error);
                        }
                    });
                }];
            } else {
                [result setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    dispatch_main_async_safe(^{
                        NSLog(@"asset url(%@) should be delete . Error:%@ ", assetURL, error);
                        if (complete) {
                            complete(error);
                        }
                    });
                }];
            }
        }
    }
#endif
}

- (void)deleteAssetCollections:(NSArray <PHAssetCollection *> *)collections complete:(void (^)(NSError *error))complete
{
    [self deleteAssetCollections:collections deleteAssets:NO complete:complete];
}

- (void)deleteAssetCollections:(NSArray <PHAssetCollection *> *)collections deleteAssets:(BOOL)deleteAssets complete:(void (^)(NSError *error))complete
{
    if (@available(iOS 8.0, *)){
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            if (deleteAssets) {
                PHFetchOptions *option = [[PHFetchOptions alloc] init];
                for (PHAssetCollection *collection in collections) {
                    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
                    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, fetchResult.count)];
                    NSArray *results = [fetchResult objectsAtIndexes:indexSet];
                    [PHAssetChangeRequest deleteAssets:results];
                }
            }
            [PHAssetCollectionChangeRequest deleteAssetCollections:collections];
        } completionHandler:^(BOOL success, NSError *error) {
            dispatch_main_async_safe(^{
                NSLog(@"deleteAssetCollections Error: %@", error);
                if (complete) {
                    complete(error);
                }
            });
        }];
    }
}


@end
