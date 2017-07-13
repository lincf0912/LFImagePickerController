//
//  LFPhotoPreviewVideoCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/7/12.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFPhotoPreviewCell.h"

@interface LFPhotoPreviewVideoCell : LFPhotoPreviewCell

@property (nonatomic, readonly) BOOL isPlaying;

- (void)didPauseCell;
@end
