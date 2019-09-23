//
//  LFAlbumCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAlbumCell.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "LFAlbum.h"

@interface LFAlbumCell ()
@property (nonatomic, weak) UIImageView *posterImageView;
@property (nonatomic, weak) UILabel *titleLabel;
@end

@implementation LFAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setModel:(LFAlbum *)model {
    _model = model;
    _titleLabel.text = nil;
    _posterImageView.image = nil;
    [self updateTraitColor];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self updateTraitColor];
}

- (void)updateTraitColor
{
    UIColor *color = nil;
    UIColor *placeholderColor = nil;
    if (@available(iOS 13.0, *)) {
        color = [UIColor labelColor];
        placeholderColor = [UIColor placeholderTextColor];
    } else {
        color = [UIColor blackColor];
        placeholderColor = [UIColor lightGrayColor];
    }
    NSMutableAttributedString *nameString = [[NSMutableAttributedString alloc] initWithString:self.model.name attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:color}];
    NSAttributedString *countString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  (%zd)", self.model.count] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:placeholderColor}];
    [nameString appendAttributedString:countString];
    self.titleLabel.attributedText = nameString;
}

- (void)setPosterImage:(UIImage *)posterImage
{
    [self.posterImageView setImage:posterImage];
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
    _posterImageView.centerY = self.contentView.height/2;
    _titleLabel.centerY = self.contentView.height/2;
}

+ (CGFloat)cellHeight
{
    return 70.f;
}

#pragma mark - Lazy load

- (UIImageView *)posterImageView {
    if (_posterImageView == nil) {
        UIImageView *posterImageView = [[UIImageView alloc] init];
        posterImageView.contentMode = UIViewContentModeScaleAspectFill;
        posterImageView.clipsToBounds = YES;
        posterImageView.frame = CGRectMake(0, 0, 70, 70);
        [self.contentView addSubview:posterImageView];
        _posterImageView = posterImageView;
    }
    return _posterImageView;
}

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.font = [UIFont boldSystemFontOfSize:17];
        titleLabel.frame = CGRectMake(80, 0, self.width - 80 - 50, self.height);
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:titleLabel];
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}

@end
