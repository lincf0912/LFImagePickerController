//
//  LFAlbum+SmartAlbum.m
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2020/5/12.
//  Copyright © 2020 LamTsanFeng. All rights reserved.
//

#import "LFAlbum+SmartAlbum.h"
#import <Photos/Photos.h>

@implementation LFAlbum (SmartAlbum)

- (LFAlbumSmartAlbum)smartAlbum
{
    if ([self.album isKindOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *collection = (PHAssetCollection *)self.album;
        if (collection.assetCollectionType == PHAssetCollectionTypeSmartAlbum) {
            switch (collection.assetCollectionSubtype) {
                case PHAssetCollectionSubtypeSmartAlbumVideos:
                    return LFAlbumSmartAlbumVideos;
                case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
                    return LFAlbumSmartAlbumUserLibrary;
                case PHAssetCollectionSubtypeSmartAlbumLivePhotos:
                    return LFAlbumSmartAlbumLivePhoto;
                case PHAssetCollectionSubtypeSmartAlbumAnimated:
                    return LFAlbumSmartAlbumAnimated;
                default:
                    break;
            }
        }
    }
    return 0;
}

@end
