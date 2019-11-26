//
//  LFAlbumTitleView.m
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2019/9/24.
//  Copyright © 2019 LamTsanFeng. All rights reserved.
//

#import "LFAlbumTitleView.h"
#import "LFAlbumCell.h"
#import "LFImagePickerHeader.h"

#define LFAlbumTitleViewBackgroundColor [UIColor colorWithWhite:0.2 alpha:0.2]

@interface LFAlbumTitleView () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIControl *control;
@property(nonatomic, weak) UIImageView *imageView;
@property(nonatomic, weak) UILabel *titleLabel;
@property(nonatomic, weak) UIView *cornerView;
@property(nonatomic, weak) CAShapeLayer *cornerViewMaskLayer;
@property(nonatomic, strong) UIView *backgroundView;

@property(nonatomic, weak) CALayer *controlMaskLayer;
@property(nonatomic, weak) CALayer *titleLabelMaskLayer;
@property(nonatomic, weak) CALayer *imageViewMaskLayer;

@property(nonatomic, weak) UITableView *tableView;

@property(nonatomic, weak) UIViewController *contentViewController;
/** 记录默认的序列 */
@property(nonatomic, assign) NSInteger tmpIndex;

/** 正在执行动画 */
@property(nonatomic, assign, getter=isAnimating) BOOL animating;

@property(nonatomic, assign) BOOL enableAnimated;

@end

@implementation LFAlbumTitleView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController
{
    self = [self init];
    if (self) {
        _contentViewController = contentViewController;
    }
    return self;
}

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController index:(NSInteger)index
{
    self = [self initWithContentViewController:contentViewController];
    if (self) {
        _tmpIndex = index;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self updateTitleView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)customInit
{
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44.0);
    _titleFont = [UIFont boldSystemFontOfSize:18];
    _titleColor = [UIColor colorWithRed:238/255.0 green:233/255.0 blue:233/255.0 alpha:1.0];
    _tapBackgroundHidden = YES;
    
    UIControl *control = [[UIControl alloc] initWithFrame:self.bounds];
    control.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    control.clipsToBounds = YES;
    [control addTarget:self action:@selector(tapCall) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:control];
    _control = control;
    
    // title view
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setFont:[self titleFont]];
    [titleLabel setTextColor:[self titleColor]];
    [titleLabel setTextAlignment:NSTextAlignmentLeft];
    titleLabel.opaque = NO;
    titleLabel.numberOfLines = 1;
    titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.control addSubview:titleLabel];
    _titleLabel = titleLabel;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:1.f]];
    [imageView setImage:bundleImageNamed(@"titleView_arrow")];
    [imageView setContentScaleFactor:[[UIScreen mainScreen] scale]];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.control addSubview:imageView];
    _imageView = imageView;
    
    // 监听屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
   
    if (self.superview) {
        
        NSAssert(self.contentViewController, @"contentViewController is null");
        
        if (!self.selectedAlbum) {
            if (self.albumArr.count) {
                _selectedAlbum = [self.albumArr objectAtIndex:self.tmpIndex];
                if (self.title) {
                    self.titleLabel.text = self.title;
                } else {
                    self.titleLabel.text = _selectedAlbum.name;
                    self.tmpIndex = 0;
                }
                /** 重置状态 */
                _state = LFAlbumTitleViewStateInactive;
                
                [self createMenuView];
            } else {
                if (self.title) {
                    self.titleLabel.text = self.title;
                } else {
                    self.titleLabel.text = self.contentViewController.title;
                }
            }
        }
    } else {
        // 释放
        [self.backgroundView removeFromSuperview];
        _state = LFAlbumTitleViewStateInactive;
    }
}

- (void)setState:(LFAlbumTitleViewState)state
{
    if (self.superview == nil) return;
    if (_state != state) {
        _state = state;
        switch (state) {
            case LFAlbumTitleViewStateInactive:
            {
                [self hiddenMenu];
            }
                break;
                
            case LFAlbumTitleViewStateActivity:
            {
                [self showMenu];
            }
                break;
        }
    }
}

- (NSInteger)index
{
    if (self.selectedAlbum) {
        return [self.albumArr indexOfObject:self.selectedAlbum];
    }
    return -1;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    if (self.superview) {
        self.titleLabel.text = self.title;
        [self setNeedsLayout];
    }
}

- (void)setAlbumArr:(NSArray<LFAlbum *> *)albumArr
{
    _albumArr = albumArr;
    if (self.superview) {
        if (self.selectedAlbum && ![self.albumArr containsObject:self.selectedAlbum]) {
            _selectedAlbum = nil;
            if (self.title) {
                self.titleLabel.text = self.title;
            } else {
                LFAlbum *album = self.albumArr.firstObject;
                self.titleLabel.text = album.name;
                _selectedAlbum = album;
            }
            [self setNeedsLayout];
        }
        [self.tableView reloadData];
    }
}

- (void)createMenuView
{
    UIView *view = self.contentViewController.view;
    // 背景view
    UIView *backgroundView = [[UIView alloc] initWithFrame:view.bounds];
    [backgroundView setBackgroundColor:[UIColor clearColor]];
    _backgroundView = backgroundView;
    
    // 背景手势
    UITapGestureRecognizer *backgroundViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundViewTapCall)];
    [backgroundViewTapGesture setDelegate:self];
    [backgroundView addGestureRecognizer:backgroundViewTapGesture];
    
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = view.safeAreaInsets;
    }
    
    CGFloat naviMaxY = CGRectGetMaxY(self.contentViewController.navigationController.navigationBar.frame);
    
    // 圆角
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(0, naviMaxY, backgroundView.bounds.size.width, backgroundView.bounds.size.height-naviMaxY-safeAreaInsets.bottom-34)];
    cornerView.backgroundColor = [UIColor clearColor];
    
    [backgroundView addSubview:cornerView];
    _cornerView = cornerView;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:cornerView.bounds style:UITableViewStylePlain];
    tableView.backgroundColor = [UIColor colorWithRed:47.0/255.0 green:47.0/255.0 blue:47.0/255.0 alpha:1.0];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.tableFooterView = [[UIView alloc] init];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[LFAlbumCell class] forCellReuseIdentifier:@"LFAlbumCell"];
    tableView.separatorColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    tableView.separatorInset = UIEdgeInsetsZero;
    /** 这个设置iOS9以后才有，主要针对iPad，不设置的话，分割线左侧空出很多 */
    if (@available(iOS 9.0, *))
    {
        if ([tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
            tableView.cellLayoutMarginsFollowReadableWidth = NO;
        }
    }
    if (@available(iOS 11.0, *))
    {
        if ([tableView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)])
        {
            [tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    tableView.contentInset = UIEdgeInsetsMake(0, safeAreaInsets.left, 0, safeAreaInsets.right);
    
    [cornerView addSubview:tableView];
    _tableView = tableView;
}

#pragma mark - action
- (void)tapCall
{
    self.state = (self.state == LFAlbumTitleViewStateActivity) ? LFAlbumTitleViewStateInactive : LFAlbumTitleViewStateActivity;
}

- (void)backgroundViewTapCall
{
    self.state = LFAlbumTitleViewStateInactive;
}

#pragma mark - show / hiden
- (void)showMenu
{
    [self updateBackgroundView];
    UIView *view = self.contentViewController.view;
    CGRect showRect = view.bounds;
    showRect.origin.y -= showRect.size.height;
    self.backgroundView.frame = showRect;
    self.backgroundView.alpha = 0.0;
    [view addSubview:self.backgroundView];
    
    self.animating = YES;
    [UIView animateWithDuration:0.25f animations:^{
        [self.imageView setTransform:CGAffineTransformMakeRotation(M_PI)];
        self.backgroundView.frame = view.bounds;
        self.backgroundView.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.animating = NO;
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    }];
}

- (void)hiddenMenu
{
    UIView *view = self.contentViewController.view;
    CGRect hidenRect = view.bounds;
    hidenRect.origin.y -= hidenRect.size.height;
    self.backgroundView.backgroundColor = [UIColor clearColor];
    
    self.animating = YES;
    [UIView animateWithDuration:0.25f animations:^{
        [self.imageView setTransform:CGAffineTransformMakeRotation(-M_PI * 2)];
        self.backgroundView.frame = hidenRect;
        self.backgroundView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.backgroundView.frame = view.bounds;
        self.backgroundView.alpha = 1.0;
        [self.backgroundView removeFromSuperview];
        self.animating = NO;
    }];
    
    if (self.didSelected) {
        self.didSelected(self.selectedAlbum, self.index);
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch view] == [self backgroundView])
    {
        return YES;
    }
    
    return NO;
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LFAlbumCell"];
    
    LFAlbum *album = _albumArr[indexPath.row];
    cell.album = album;
    
    if ([self.selectedAlbum isEqual:album]) {
        [cell setSelectedImage:bundleImageNamed(self.selectImageName)];
    } else {
        [cell setSelectedImage:nil];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    LFAlbum *model = _albumArr[indexPath.row];
    
    NSIndexPath *selectedIndexPath = nil;
    if (self.selectedAlbum) {
        if ([model isEqual:self.selectedAlbum]) {
            self.state = LFAlbumTitleViewStateInactive;
            return;
        }
        /** 取消所选 */
        NSInteger index = [self.albumArr indexOfObject:self.selectedAlbum];
        selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    }
    
    _selectedAlbum = model;
    self.titleLabel.text = model.name;
    self.enableAnimated = YES;
    [self setNeedsDisplay];
    [self setNeedsLayout];
    
    [tableView beginUpdates];
    if (selectedIndexPath) {
        [tableView reloadRowsAtIndexPaths:@[selectedIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [tableView endUpdates];
    
    self.state = LFAlbumTitleViewStateInactive;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [LFAlbumCell cellHeight];
}

#pragma mark - private

#pragma mark update frame
- (void)updateTitleView
{
    CGFloat margin = 7.0;
    CGFloat insetMargin = 6.0;
    CGSize imageSize = _imageView.image.size;
    if (self.frame.size.height - 2*margin < imageSize.height) {
        CGFloat tmpHeight = imageSize.height;
        imageSize.height = self.frame.size.height - 2*margin;
        imageSize.width = imageSize.width*imageSize.height/tmpHeight;
        insetMargin = MIN(2.0, insetMargin-tmpHeight+imageSize.height);
    }

    CGSize textSize = [_titleLabel.text boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:_titleLabel.font, NSForegroundColorAttributeName:_titleLabel.textColor} context:nil].size;
    textSize.width = ceil(textSize.width)+1.0;
    
    CGRect rect = self.control.frame;
    rect.size.height = self.frame.size.height;
    rect.size.width = textSize.width + margin*2.0;
    if (imageSize.width > 0) {
        rect.size.width += imageSize.width + margin;
    }
    self.control.hidden = (self.titleLabel.text.length == 0);
    
    if (self.control.isHidden) return;
    
    CGRect oldRect = self.control.frame;
    CGRect oldMaskRect = self.controlMaskLayer.frame;
//    CGRect oldTitleLabelRect = self.titleLabel.frame;
    CGRect oldTitlelabelMaskRect = self.titleLabelMaskLayer.frame;
    CGRect oldImageRect = self.imageView.frame;
    CGRect oldImageMaskRect = self.imageViewMaskLayer.frame;
    
    self.control.frame = rect;
    CGPoint center = self.center;
    // 相对屏幕的坐标
    CGRect screenFrame = [self convertRect:self.frame toView:nil];
    // 调整x轴的偏移量
    center.x += -CGRectGetMinX(screenFrame)/2 + ([UIScreen mainScreen].bounds.size.width - CGRectGetMaxX(screenFrame))/2;
    self.control.center = center;
    
    // draw background
    CGRect controllBounds = CGRectInset(self.control.bounds, 0, insetMargin);
    if (self.controlMaskLayer == nil) {
        CALayer *layer = [self createMaskLayer];
        self.control.layer.mask = layer;
        self.controlMaskLayer = layer;
    }
    self.controlMaskLayer.bounds = (CGRect){CGPointZero, controllBounds.size};
    self.controlMaskLayer.position = controllBounds.origin;
    self.controlMaskLayer.cornerRadius = CGRectGetHeight(controllBounds)/2;
    
    CGRect titleLabelRect = CGRectMake(margin, (CGRectGetHeight(rect)-textSize.height)/2, textSize.width, textSize.height);
    self.titleLabel.frame = titleLabelRect;
    if (self.titleLabelMaskLayer == nil) {
        CALayer *layer = [self createMaskLayer];
        self.titleLabel.layer.mask = layer;
        self.titleLabelMaskLayer = layer;
    }
    self.titleLabelMaskLayer.bounds = self.titleLabel.bounds;
    
    self.imageView.frame = CGRectMake(CGRectGetMaxX(titleLabelRect)+margin, (CGRectGetHeight(rect)-imageSize.height)/2, imageSize.width, imageSize.height);
    CGRect imageViewBounds = self.imageView.bounds;
    if (self.imageViewMaskLayer == nil) {
        CALayer *layer = [self createMaskLayer];
        self.imageView.layer.mask = layer;
        self.imageViewMaskLayer = layer;
    }
    self.imageViewMaskLayer.bounds = (CGRect){CGPointZero, imageViewBounds.size};
    self.imageViewMaskLayer.cornerRadius = CGRectGetHeight(imageViewBounds)/2;
    
    if (self.enableAnimated)
    {
        CGFloat duration = .25;
        [self makeAnimationWithDruation:duration layer:self.control.layer oldRect:oldRect cornerRadius:NO];
        [self makeAnimationWithDruation:duration layer:self.controlMaskLayer oldRect:oldMaskRect cornerRadius:YES];
//        [self makeAnimationWithDruation:duration layer:self.titleLabel.layer oldRect:oldTitleLabelRect cornerRadius:NO];
        [self makeAnimationWithDruation:duration layer:self.titleLabelMaskLayer oldRect:oldTitlelabelMaskRect cornerRadius:NO];
        [self makeAnimationWithDruation:duration layer:self.imageView.layer oldRect:oldImageRect cornerRadius:NO];
        [self makeAnimationWithDruation:duration layer:self.imageViewMaskLayer oldRect:oldImageMaskRect cornerRadius:YES];
    }
    
    self.enableAnimated = NO;
}

- (void)updateBackgroundView
{
    UIView *view = self.contentViewController.view;
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = view.safeAreaInsets;
    }
    
    CGFloat naviMaxY = CGRectGetMaxY(self.contentViewController.navigationController.navigationBar.frame);
    
    self.backgroundView.frame = view.bounds;
    // 圆角
    self.cornerView.frame = CGRectMake(0, naviMaxY, self.backgroundView.bounds.size.width, self.backgroundView.bounds.size.height-naviMaxY-safeAreaInsets.bottom-40);
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.cornerView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8, 8)];
    if (self.cornerViewMaskLayer == nil) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.cornerView.bounds;
        self.cornerView.layer.mask = maskLayer;
        self.cornerViewMaskLayer = maskLayer;
    }
    self.cornerViewMaskLayer.path = maskPath.CGPath;
}

#pragma mark animated
- (void)makeAnimationWithDruation:(CGFloat)duration layer:(CALayer *)layer oldRect:(CGRect)oldRect cornerRadius:(BOOL)cornerRadius
{
    CGRect newRect = layer.frame;
    if (!CGSizeEqualToSize(oldRect.size, newRect.size)) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"bounds"];
        animate.duration = duration;
        animate.fromValue = [NSValue valueWithCGRect:(CGRect){CGPointZero, oldRect.size}];
        animate.toValue = [NSValue valueWithCGRect:(CGRect){CGPointZero, newRect.size}];
        [layer addAnimation:animate forKey:@"BoundsAnimationKey"];
    }
    
    if (!CGPointEqualToPoint(oldRect.origin, newRect.origin)) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"position"];
        animate.duration = duration;
        animate.fromValue = [NSValue valueWithCGPoint:CGPointMake(oldRect.origin.x+oldRect.size.width/2, oldRect.origin.y+oldRect.size.height/2)];
        animate.toValue = [NSValue valueWithCGPoint:CGPointMake(newRect.origin.x+newRect.size.width/2, newRect.origin.y+newRect.size.height/2)];
        [layer addAnimation:animate forKey:@"PositionAnimationKey"];
    }
    
    if (cornerRadius) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
        animate.duration = duration;
        animate.fromValue = @(CGRectGetHeight(oldRect)/2);
        animate.toValue = @(layer.cornerRadius);
        [layer addAnimation:animate forKey:@"CornerRadiusAnimationKey"];
    }
}

#pragma mark - UIDeviceOrientationDidChangeNotification
- (void)orientationDidChange:(NSNotification *)notify
{
    if (UIDeviceOrientationIsValidInterfaceOrientation([[UIDevice currentDevice] orientation])) {
        [self updateBackgroundView];
    }
}

#pragma mark - create Mask layer
- (CALayer *)createMaskLayer
{
    CALayer *layer = [CALayer layer];
    layer.anchorPoint = CGPointZero;
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    layer.masksToBounds = YES;
    layer.shouldRasterize = YES;
    layer.rasterizationScale = [UIScreen mainScreen].scale;
    return layer;
}

@end
