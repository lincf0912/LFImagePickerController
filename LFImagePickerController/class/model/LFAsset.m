//
//  LFAsset.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAsset.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation LFAsset

- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type
{
    self = [super init];
    if (self) {
        _asset = asset;
        _type = type;
        _timeLength = nil;
        _name = nil;
    }
    return self;
}

- (instancetype)initWithAsset:(id)asset type:(LFAssetMediaType)type timeLength:(NSString *)timeLength
{
    self = [self initWithAsset:asset type:type];
    if (self) {
        _timeLength = timeLength;
        if ([asset isKindOfClass:[PHAsset class]]) {
            _name = [asset valueForKey:@"filename"];
        } else if ([asset isKindOfClass:[ALAsset class]]) {
            ALAsset *alAsset = (ALAsset *)asset;
            ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
            _name = assetRep.filename;
        }
    }
    return self;
}
@end
