//
//  LFAssetManager+Authorization.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager+Authorization.h"
#import "LFImagePickerHeader.h"

@implementation LFAssetManager (Authorization)

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized
{
    NSInteger status = [self authorizationStatus];
    if (status == 0) {
        /**
         * 当某些情况下AuthorizationStatus == AuthorizationStatusNotDetermined时，无法弹出系统首次使用的授权alertView，系统应用设置里亦没有相册的设置，此时将无法使用，故作以下操作，弹出系统首次使用的授权alertView
         */
        [self requestAuthorizationWhenNotDetermined:nil];
    }
    
    return status == 3;
}

- (LFPhotoAuthorizationStatus)lf_authorizationStatusAndRequestAuthorization:(void(^)(LFPhotoAuthorizationStatus status))handler
{
    LFPhotoAuthorizationStatus status = [self lf_authorizationStatus];
    if (status == LFPhotoAuthorizationStatusNotDetermined) {
        /**
         * 当某些情况下AuthorizationStatus == AuthorizationStatusNotDetermined时，无法弹出系统首次使用的授权alertView，系统应用设置里亦没有相册的设置，此时将无法使用，故作以下操作，弹出系统首次使用的授权alertView
         */
        [self requestAuthorizationWhenNotDetermined:handler];
    }
    

    return status;
}

- (NSInteger)authorizationStatus {
    if (@available(iOS 14, *)) {
        return [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
    else
    if (@available(iOS 8.0, *)){
        return [PHPhotoLibrary authorizationStatus];
    }
    else {
        return [ALAssetsLibrary authorizationStatus];
    }
    return NO;
}

- (LFPhotoAuthorizationStatus)lf_authorizationStatus {
    if (@available(iOS 14, *)) {
        return (LFPhotoAuthorizationStatus)[PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
    else
    if (@available(iOS 8.0, *)){
        return (LFPhotoAuthorizationStatus)[PHPhotoLibrary authorizationStatus];
    }
    else {
        return (LFPhotoAuthorizationStatus)[ALAssetsLibrary authorizationStatus];
    }
    return LFPhotoAuthorizationStatusNotDetermined;
}

//AuthorizationStatus == AuthorizationStatusNotDetermined 时询问授权弹出系统授权alertView
- (void)requestAuthorizationWhenNotDetermined:(void(^)(LFPhotoAuthorizationStatus status))handler {
    if (@available(iOS 14, *)) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                
                dispatch_main_async_safe(^{
                    if (handler) {
                        handler((LFPhotoAuthorizationStatus)status);
                    }
                });
            }];
        });
    }
    else
    if (@available(iOS 8.0, *)){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                dispatch_main_async_safe(^{
                    if (handler) {
                        handler((LFPhotoAuthorizationStatus)status);
                    }
                });
            }];
        });
    }
    else {
        [self.assetLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        } failureBlock:nil];
    }
}
@end
