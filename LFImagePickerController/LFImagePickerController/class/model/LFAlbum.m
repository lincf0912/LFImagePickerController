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

- (instancetype)initWithAlbum:(id)album result:(id)result
{
    self = [super init];
    if (self) {
        [self changedAlbum:album];
        [self changedResult:result];
    }
    return self;
}

- (void)changedResult:(id)result
{
    if ([result isKindOfClass:[PHFetchResult class]]) {
        PHFetchResult *fetchResult = (PHFetchResult *)result;
        _result = result;
        _count = fetchResult.count;
    } else if ([result isKindOfClass:[ALAssetsGroup class]]) {
        ALAssetsGroup *group = (ALAssetsGroup *)result;
        _result = result;
        _count = [group numberOfAssets];
        _name = [group valueForProperty:ALAssetsGroupPropertyName];
    }
}

- (void)changedAlbum:(id)album
{
    if ([album isKindOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *collection = (PHAssetCollection *)album;
        _album = album;
        _name = collection.localizedTitle;
        
    }
}

- (BOOL)isEqual:(id)object
{
    if([self class] == [object class])
    {
        if (self == object) {
            return YES;
        }
        LFAlbum *objAlbum = (LFAlbum *)object;
        if ([self.album isEqual: objAlbum.album] && [self.name isEqual: objAlbum.name]) {
            return YES;
        }
        return NO;
    }
    else
    {
        return [super isEqual:object];
    }
}

@end
