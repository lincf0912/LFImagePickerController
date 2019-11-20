//
//  LFAlbumCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAlbumCell.h"
#import "LFImagePickerHeader.h"
#import "LFAlbum.h"
#import "LFAssetManager+Simple.h"

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"
#endif

@interface LFAlbumCell ()
@property (nonatomic, weak) UIImageView *posterImageView;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UIImageView *selectedImageView;

@end

@implementation LFAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted) {
        self.backgroundColor = [UIColor colorWithRed:24.0/255.0 green:22.0/255.0 blue:23.0/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:24.0/255.0 green:22.0/255.0 blue:23.0/255.0 alpha:1.0];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)setAlbum:(LFAlbum *)album {
    _album = album;
    _titleLabel.text = nil;
    _posterImageView.image = nil;
    [self updateTraitColor];
    
    if (album.count) {
        if (album.posterAsset == nil) { /** 没有缓存数据 */
            NSInteger index = 0;
            if ([LFAssetManager manager].sortAscendingByCreateDate) {
                index = album.count-1;
            }
            [[LFAssetManager manager] getAssetFromFetchResult:album.result
                                                      atIndex:index
                                                   completion:^(LFAsset *model) {
                
                if ([self.album isEqual:album]) {
                    self.album.posterAsset = model;
                    [self setCellPosterImage:self];
                }
            }];
        } else {
            [self setCellPosterImage:self];
        }
    } else {
        self.posterImage = bundleImageNamed(@"album_list_img_default");
    }
}

#pragma mark - 设置封面
- (void)setCellPosterImage:(LFAlbumCell *)cell
{
    LFAsset *model = cell.album.posterAsset;
    
#ifdef LF_MEDIAEDIT
    /** 优先显示编辑图片 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit.editPosterImage) {
        cell.posterImage = photoEdit.editPosterImage;
    } else {
#endif
        [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([cell.album.posterAsset isEqual:model]) {
                cell.posterImage = photo;
            }
        } progressHandler:nil networkAccessAllowed:YES];
#ifdef LF_MEDIAEDIT
    }
#endif
}

- (void)updateTraitColor
{
    UIColor *color = [UIColor whiteColor];
    UIColor *placeholderColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:self.album.name attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17],NSForegroundColorAttributeName:color}];
    NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)", self.album.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17],NSForegroundColorAttributeName:placeholderColor}];
    [nameString appendAttributedString:countString];
    self.titleLabel.attributedText = nameString;
}

- (void)setPosterImage:(UIImage *)posterImage
{
    [self.posterImageView setImage:posterImage];
}

- (UIImage *)posterImage
{
    return self.posterImageView.image;
}

- (void)setSelectedImage:(UIImage *)image
{
    self.selectedImageView.image = image;
    [_selectedImageView setHidden:image == nil];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.posterImage = nil;
}

/// For fitting iOS6
- (void)layoutSubviews {
    [super layoutSubviews];
    
    /** 居中 */
    self.posterImageView.frame = CGRectMake(0, 0, self.contentView.frame.size.height, self.contentView.frame.size.height);
    self.selectedImageView.frame = CGRectMake(self.contentView.frame.size.width - 30 - 10, (self.contentView.frame.size.height - 30)/2, 30, 30);
    CGFloat left = _posterImageView.frame.size.width+10;
    CGFloat right = self.contentView.frame.size.width - (_selectedImageView.frame.origin.x+10);
    self.titleLabel.frame = CGRectMake(left, 0, self.contentView.frame.size.width - (left + right), self.contentView.frame.size.height);
}

+ (CGFloat)cellHeight
{
    return 55.0;
}

#pragma mark - Lazy load

- (UIImageView *)posterImageView {
    if (_posterImageView == nil) {
        UIImageView *posterImageView = [[UIImageView alloc] init];
        posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        posterImageView.clipsToBounds = YES;
        posterImageView.frame = CGRectMake(0, 0, self.contentView.frame.size.height, self.contentView.frame.size.height);
        [self.contentView addSubview:posterImageView];
        _posterImageView = posterImageView;
    }
    return _posterImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont boldSystemFontOfSize:17];
        titleLabel.frame = CGRectMake(self.contentView.frame.size.height, 0, self.contentView.frame.size.width - self.contentView.frame.size.height - 50, self.contentView.frame.size.height);
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:titleLabel];
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}

- (UIImageView *)selectedImageView
{
    if (_selectedImageView == nil) {
        UIImageView *selectedImageView = [[UIImageView alloc] init];
        selectedImageView.contentMode = UIViewContentModeScaleAspectFit;
        selectedImageView.clipsToBounds = YES;
        selectedImageView.frame = CGRectMake(self.contentView.frame.size.width-30-10, (self.contentView.frame.size.height-30)/2, 30, 30);
        [self.contentView addSubview:selectedImageView];
        _selectedImageView = selectedImageView;
    }
    return _selectedImageView;
}

@end
