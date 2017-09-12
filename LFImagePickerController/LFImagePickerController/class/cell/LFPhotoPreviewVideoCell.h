//
//  LFPhotoPreviewVideoCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"
#import <AVFoundation/AVFoundation.h>

@interface LFPhotoPreviewVideoCell : LFPhotoPreviewCell

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) AVAsset *asset;

- (void)didPlayCell;
- (void)didPauseCell;
- (void)changeVideoPlayer:(AVAsset *)asset image:(UIImage *)image;
@end
