//
//  LFResultObject.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFResultObject.h"

@implementation LFResultObject

- (void)setAsset:(id)asset
{
    _asset = asset;
}

- (void)setInfo:(LFResultInfo *)info
{
    _info = info;
}

- (void)setError:(NSError *)error
{
    _error = error;
}

+ (LFResultObject *)errorResultObject:(id)asset
{
    LFResultObject *object = [[LFResultObject alloc] init];
    object.asset = asset;
    object.error = [NSError errorWithDomain:@"asset error" code:-1 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Asset:%@ cannot extract data", asset]}];
    return object;
}

@end
