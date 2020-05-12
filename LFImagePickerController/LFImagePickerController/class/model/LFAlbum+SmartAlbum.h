//
//  LFAlbum+SmartAlbum.h
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2020/5/12.
//  Copyright © 2020 LamTsanFeng. All rights reserved.
//

#import "LFAlbum.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, LFAlbumSmartAlbum) {
    LFAlbumSmartAlbumVideos = 1,
    LFAlbumSmartAlbumUserLibrary,
    LFAlbumSmartAlbumLivePhoto,
    LFAlbumSmartAlbumAnimated,
};

@interface LFAlbum (SmartAlbum)

@property (nonatomic, readonly) LFAlbumSmartAlbum smartAlbum NS_AVAILABLE_IOS(8_0) __TVOS_PROHIBITED;

@end

NS_ASSUME_NONNULL_END
