//
//  LFAlbum.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAlbum.h"
#import "LFAsset.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation LFAlbum

- (instancetype)initWithName:(NSString *)name result:(id)result
{
    self = [super init];
    if (self) {
        _name = name;
        _result = result;
        
        if ([result isKindOfClass:[PHFetchResult class]]) {
            PHFetchResult *fetchResult = (PHFetchResult *)result;
            _count = fetchResult.count;
        } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
            ALAssetsGroup *group = (ALAssetsGroup *)result;
            _count = [group numberOfAssets];
        }
    }
    return self;
}

@end
