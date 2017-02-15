//
//  LFAlbumCell.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LFAlbum;
@interface LFAlbumCell : UITableViewCell

@property (nonatomic, strong) LFAlbum *model;
/** 封面 */
@property (nonatomic, setter=setPosterImage:) UIImage *posterImage;

+ (CGFloat)cellHeight;

@end
