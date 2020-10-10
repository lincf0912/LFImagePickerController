//
//  LFPhotoPreviewVideoCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"
#import <AVFoundation/AVFoundation.h>

@class LFPhotoPreviewVideoCell;
@protocol LFPhotoPreviewVideoCellDelegate <NSObject, LFPhotoPreviewCellDelegate>
@optional
- (void)lf_photoPreviewVideoCellDidPlayHandler:(LFPhotoPreviewVideoCell *)cell;
- (void)lf_photoPreviewVideoCellDidStopHandler:(LFPhotoPreviewVideoCell *)cell;
@end

@interface LFPhotoPreviewVideoCell : LFPhotoPreviewCell

@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) AVAsset *asset;
@property (nonatomic, weak) id<LFPhotoPreviewVideoCellDelegate> delegate;

- (void)didPlayCell;
- (void)didPauseCell;
//- (void)changeVideoPlayer:(AVAsset *)asset image:(UIImage *)image;
@end


