//
//  LFAssetCell.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetCell.h"
#import "LFImagePickerHeader.h"
#import "LFAsset.h"
#import "LFAssetManager.h"
#import "UIView+LFFrame.h"
#import "UIView+LFAnimate.h"
#import "UIImage+LFCommon.h"
#import "LFPhotoEditManager.h"
#ifdef LF_MEDIAEDIT
#import "LFPhotoEdit.h"
#import "LFVideoEditManager.h"
#import "LFVideoEdit.h"
#endif

#pragma mark - /// 宫格图片视图

#define kAdditionalSize (isiPad ? 15 : 0)
#define kVideoBoomHeight (20.f + kAdditionalSize)

@interface LFAssetCell ()
@property (weak, nonatomic) UIImageView *imageView;       // The photo / 照片
@property (weak, nonatomic) UIImageView *selectImageView;
@property (weak, nonatomic) UIImageView *editMaskImageView;
@property (weak, nonatomic) UIView *bottomView;
@property (weak, nonatomic) UIButton *selectPhotoButton;

@property (nonatomic, weak) UIImageView *videoImgView;
@property (weak, nonatomic) UILabel *timeLength;

@property (weak, nonatomic) UIView *maskHitView;
@end

@implementation LFAssetCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    
    /** 背景图片 */
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(0, 0, self.width, self.height);
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    [self.contentView addSubview:imageView];
    _imageView = imageView;
    
    /** 底部状态栏 */
    UIView *bottomView = [[UIView alloc] init];
    bottomView.frame = CGRectMake(0, self.height - kVideoBoomHeight, self.width, kVideoBoomHeight);
    [self.contentView addSubview:bottomView];
    CAGradientLayer* gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = bottomView.bounds;
    gradientLayer.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0.0f alpha:.0f] CGColor], (id)[[UIColor colorWithWhite:0.0f alpha:0.8f] CGColor], nil];
    [bottomView.layer insertSublayer:gradientLayer atIndex:0];
    bottomView.hidden = YES;
    _bottomView = bottomView;
    
    /** 状态栏 子控件 懒加载 */
    
    /** 编辑标记 */
    UIImageView *editMaskImageView = [[UIImageView alloc] init];
    CGRect frame = CGRectMake(5, 5, 13.5 + kAdditionalSize, 11 + kAdditionalSize);
    editMaskImageView.frame = frame;
    [editMaskImageView setImage:bundleImageNamed(@"contacts_add_myablum.png")];
    editMaskImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:editMaskImageView];
    _editMaskImageView = editMaskImageView;
    
    /** 选择按钮 */
    UIButton *selectPhotoButton = [[UIButton alloc] init];
    selectPhotoButton.frame = CGRectMake(self.width - 30 - kAdditionalSize, 0, 30 + kAdditionalSize, 30 + kAdditionalSize);
    [selectPhotoButton addTarget:self action:@selector(selectPhotoButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:selectPhotoButton];
    _selectPhotoButton = selectPhotoButton;
    
    UIImageView *selectImageView = [[UIImageView alloc] init];
    selectImageView.frame = CGRectMake(self.width - 28 - kAdditionalSize, 2, 26 + kAdditionalSize, 26 + kAdditionalSize);
    [self.contentView addSubview:selectImageView];
    _selectImageView = selectImageView;
    
    /** 蒙蔽层 */
    UIView *view = [[UIButton alloc] init];
    view.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
    view.frame = self.bounds;
    view.hidden = YES;
    [self.contentView addSubview:view];
    _maskHitView = view;
    
}

- (void)setModel:(LFAsset *)model {
    _model = model;

    BOOL hiddenEditMask = YES;
    if (self.model.type == LFAssetMediaTypePhoto) {
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
        if (photoEdit.editPosterImage) {
            self.imageView.image = photoEdit.editPosterImage;
            hiddenEditMask = NO;
        } else {
#endif
            [self getAssetImage:model];
#ifdef LF_MEDIAEDIT
        }
#endif
        /** 显示编辑标记 */
        self.editMaskImageView.hidden = hiddenEditMask;
    } else if (self.model.type == LFAssetMediaTypeVideo) {
#ifdef LF_MEDIAEDIT
        /** 优先显示编辑图片 */
        LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:model];
        if (videoEdit.editPosterImage) {
            self.imageView.image = videoEdit.editPosterImage;
            hiddenEditMask = NO;
        } else {
#endif
            [self getAssetImage:model];
#ifdef LF_MEDIAEDIT
        }
#endif
        /** 显示编辑标记 */
        self.editMaskImageView.hidden = hiddenEditMask;
    }
    
    
    [self setTypeToSubView];
}

- (void)getAssetImage:(LFAsset *)model
{
    if (model.previewImage) { /** 显示自定义图片 */
        self.imageView.image = model.previewImage;
    }  else {
        [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:self.width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([model.asset isEqual:self.model.asset]) {
                self.imageView.image = photo;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.imageView.image = nil;
}

- (void)setTypeToSubView {
    
    if (self.model.type == LFAssetMediaTypePhoto) {
        _bottomView.hidden = YES;
        
        if (self.displayGif && self.model.subType == LFAssetSubMediaTypeGIF) {
            _videoImgView.hidden = YES;
            self.timeLength.text = @"GIF";
            self.timeLength.textAlignment = NSTextAlignmentRight;
            _bottomView.hidden = NO;
        } else if (self.displayLivePhoto && self.model.subType == LFAssetSubMediaTypeLivePhoto) {
            _videoImgView.hidden = YES;
            self.timeLength.text = @"Live";
            self.timeLength.textAlignment = NSTextAlignmentRight;
            _bottomView.hidden = NO;
        } else if (self.displayPhotoName) {
            _videoImgView.hidden = YES;
            self.timeLength.text = [self.model.name stringByDeletingPathExtension];
            self.timeLength.textAlignment = NSTextAlignmentCenter;
            _bottomView.hidden = NO;
        }
    } else if (self.model.type == LFAssetMediaTypeVideo) {
        self.videoImgView.hidden = NO;
#ifdef LF_MEDIAEDIT
        LFVideoEdit *videoEdit = [[LFVideoEditManager manager] videoEditForAsset:self.model];
        if (videoEdit.editPosterImage) {
            self.timeLength.text = [self getNewTimeFromDurationSecond:[[NSString stringWithFormat:@"%0.0f",videoEdit.duration] integerValue]];
        } else {
#endif
            self.timeLength.text = [self getNewTimeFromDurationSecond:[[NSString stringWithFormat:@"%0.0f",self.model.duration] integerValue]];
#ifdef LF_MEDIAEDIT
        }
#endif
        self.timeLength.textAlignment = NSTextAlignmentRight;
        _bottomView.hidden = NO;
    }
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

- (void)setOnlySelected:(BOOL)onlySelected
{
    _onlySelected = onlySelected;
    if (onlySelected) {
        _selectPhotoButton.frame = self.bounds;
    } else {
        _selectPhotoButton.frame = CGRectMake(self.width - 30 - kAdditionalSize, 0, 30 + kAdditionalSize, 30 + kAdditionalSize);
    }
}

- (void)setNoSelected:(BOOL)noSelected
{
    _noSelected = noSelected;
    self.maskHitView.hidden = !noSelected;
}

- (void)selectPhotoButtonClick:(UIButton *)sender {
    if (self.didSelectPhotoBlock) {
        __weak typeof(self) weakSelf = self;
        self.didSelectPhotoBlock(!sender.selected, self.model, weakSelf);
    }
}

- (void)selectPhoto:(BOOL)isSelected index:(NSUInteger)index animated:(BOOL)animated
{
    self.selectPhotoButton.selected = isSelected;
    UIImage *image = nil;
    if (_selectPhotoButton.selected) {
        NSString *text = [NSString stringWithFormat:@"%zd", index];
        image = [UIImage lf_mergeImage:bundleImageNamed(self.photoSelImageName) text:text];
    } else {
        image = bundleImageNamed(self.photoDefImageName);
    }
    self.selectImageView.image = image;
    if (animated) {
        [UIView showOscillatoryAnimationWithLayer:_selectImageView.layer type:OscillatoryAnimationToBigger];
    }
}

#pragma mark - Lazy load
- (UIImageView *)videoImgView {
    if (_videoImgView == nil) {
        UIImageView *videoImgView = [[UIImageView alloc] init];
        videoImgView.frame = CGRectMake(8, 0, 18, 11);
        videoImgView.contentMode = UIViewContentModeScaleAspectFit;
        [videoImgView setImage:bundleImageNamed(@"fileicon_video_wall.png")];
        [self.bottomView addSubview:videoImgView];
        _videoImgView = videoImgView;
    }
    return _videoImgView;
}

- (UILabel *)timeLength {
    if (_timeLength == nil) {
        UILabel *timeLength = [[UILabel alloc] init];
        timeLength.font = [UIFont boldSystemFontOfSize:isiPad ? 17 : 11];
        CGFloat height = [@"A" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, kVideoBoomHeight) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:timeLength.font} context:nil].size.height;
        
        CGFloat videoImageMaxX = MAX(CGRectGetMaxX(_videoImgView.frame), 8);
        
        timeLength.frame = CGRectMake(videoImageMaxX, (11-height)/2, self.width - videoImageMaxX - 8, height);
        timeLength.textColor = [UIColor whiteColor];
        timeLength.textAlignment = NSTextAlignmentRight;
        timeLength.lineBreakMode = NSLineBreakByTruncatingHead;
        [self.bottomView addSubview:timeLength];
        _timeLength = timeLength;
    }
    return _timeLength;
}

@end

#pragma mark - /// 拍照视图

@interface LFAssetCameraCell ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation LFAssetCameraCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _imageView = [[UIImageView alloc] init];
        _imageView.backgroundColor = [UIColor colorWithWhite:1.000 alpha:0.500];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)setPosterImage:(UIImage *)posterImage
{
    _posterImage = posterImage;
    [self.imageView setImage:posterImage];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.bounds;
}

@end
