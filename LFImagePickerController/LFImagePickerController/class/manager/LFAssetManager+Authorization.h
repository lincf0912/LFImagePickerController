//
//  LFAssetManager+Authorization.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"

typedef NS_ENUM(NSInteger, LFPhotoAuthorizationStatus) {
    /** 未询问过的 */
    LFPhotoAuthorizationStatusNotDetermined = 0,
    /** 被限制的 */
    LFPhotoAuthorizationStatusRestricted,
    /** 拒绝的 */
    LFPhotoAuthorizationStatusDenied,
    /** 允许访问所有 */
    LFPhotoAuthorizationStatusAuthorized,
    /** 允许访问部分 */
    LFPhotoAuthorizationStatusLimited
};


@interface LFAssetManager (Authorization)

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized API_DEPRECATED_WITH_REPLACEMENT("-lf_authorizationStatusAndRequestAuthorization:", ios(8, API_TO_BE_DEPRECATED));
- (NSInteger)authorizationStatus API_DEPRECATED_WITH_REPLACEMENT("-lf_authorizationStatus:", ios(8, API_TO_BE_DEPRECATED));

- (LFPhotoAuthorizationStatus)lf_authorizationStatusAndRequestAuthorization:(void(^)(LFPhotoAuthorizationStatus status))handler;
- (LFPhotoAuthorizationStatus)lf_authorizationStatus;

@end
