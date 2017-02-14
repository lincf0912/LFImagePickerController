//
//  LFAsset.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAsset.h"

@implementation LFAsset

- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type
{
    self = [super init];
    if (self) {
        _asset = asset;
        _type = type;
    }
    return self;
}

- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type timeLength:(NSString *)timeLength
{
    self = [self initWithAsset:asset type:type];
    if (self) {
        _timeLength = timeLength;
    }
    return self;
}
@end
