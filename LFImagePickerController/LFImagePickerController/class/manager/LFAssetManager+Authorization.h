//
//  LFAssetManager+Authorization.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"

@interface LFAssetManager (Authorization)

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized;
- (NSInteger)authorizationStatus;

@end
