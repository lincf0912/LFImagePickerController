//
//  LFAblumTitleView.m
//  LFImagePickerController
//
//  Created by TsanFeng Lam on 2019/9/24.
//  Copyright © 2019 LamTsanFeng. All rights reserved.
//

#import "LFAblumTitleView.h"
#import "LFAlbumCell.h"
#import "LFImagePickerHeader.h"

#define LFAblumTitleViewBackgroundColor [UIColor colorWithWhite:0.2 alpha:0.2]

@interface LFAblumTitleView () <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIControl *control;
@property(nonatomic, weak) UIImageView *imageView;
@property(nonatomic, weak) UILabel *titleLabel;
@property(nonatomic, weak) UIView *cornerView;
@property(nonatomic, strong) UIView *backgroundView;

@property(nonatomic, weak) CAShapeLayer *shapeLayer;
@property(nonatomic, weak) CAShapeLayer *imageViewShapeLayer;

@property(nonatomic, weak) UITableView *tableView;

@property(nonatomic, weak) UIViewController *currentVC;
/** 记录默认的序列 */
@property(nonatomic, assign) NSInteger tmpIndex;

/** 正在执行动画 */
@property(nonatomic, assign, getter=isAnimating) BOOL animating;

@property(nonatomic, assign) BOOL enableAnimated;

@end

@implementation LFAblumTitleView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

+ (instancetype)titleView
{
    return [[self alloc] init];
}

- (instancetype)initWithIndex:(NSInteger)index
{
    self = [self init];
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

- (void)customInit
{
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44.0);
    _titleFont = [UIFont boldSystemFontOfSize:18];
    _titleColor = [UIColor colorWithRed:238/255.0 green:233/255.0 blue:233/255.0 alpha:1.0];
    _tapBackgroundHidden = YES;
    
    UIControl *control = [[UIControl alloc] initWithFrame:self.bounds];
    control.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
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
}

+ (BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
   
    if (self.superview) {
        self.currentVC = [self getCurrentVC];
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
                _state = LFAblumTitleViewStateInactive;
                
                [self createMenuView];
            } else {
                if (self.title) {
                    self.titleLabel.text = self.title;
                } else {
                    self.titleLabel.text = self.currentVC.title;
                }
            }
        }
    } else {
        self.currentVC = nil;
        // 释放
        [self.backgroundView removeFromSuperview];
        _state = LFAblumTitleViewStateInactive;
    }
}

- (void)setState:(LFAblumTitleViewState)state
{
    if (self.superview == nil) return;
    if (_state != state) {
        _state = state;
        switch (state) {
            case LFAblumTitleViewStateInactive:
            {
                [self hiddenMenu];
            }
                break;
                
            case LFAblumTitleViewStateActivity:
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
    UIView *view = self.currentVC.view;
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
    
    // 圆角
    UIView *cornerView = [[UIView alloc] initWithFrame:CGRectMake(0, safeAreaInsets.top, backgroundView.bounds.size.width, backgroundView.bounds.size.height-safeAreaInsets.top-safeAreaInsets.bottom-34)];
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
    self.state = (self.state == LFAblumTitleViewStateActivity) ? LFAblumTitleViewStateInactive : LFAblumTitleViewStateActivity;
}

- (void)backgroundViewTapCall
{
    self.state = LFAblumTitleViewStateInactive;
}

#pragma mark - show / hiden
- (void)showMenu
{
    UIView *view = self.currentVC.view;
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
    }];
}

- (void)hiddenMenu
{
    UIView *view = self.currentVC.view;
    CGRect hidenRect = view.bounds;
    hidenRect.origin.y -= hidenRect.size.height;
    
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
            self.state = LFAblumTitleViewStateInactive;
            return;
        }
        /** 取消所选 */
        NSInteger index = [self.albumArr indexOfObject:self.selectedAlbum];
        selectedIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    }
    
    _selectedAlbum = model;
    self.titleLabel.text = model.name;
    self.enableAnimated = YES;
    [self setNeedsLayout];
    
    [tableView beginUpdates];
    if (selectedIndexPath) {
        [tableView reloadRowsAtIndexPaths:@[selectedIndexPath, indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [tableView endUpdates];
    
    self.state = LFAblumTitleViewStateInactive;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [LFAlbumCell cellHeight];
}

#pragma mark - private

#pragma mark update frame
- (void)updateTitleView
{
    // 列表
    if (!self.isAnimating) {
        UIView *view = self.currentVC.view;
        UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
        if (@available(iOS 11.0, *)) {
            safeAreaInsets = view.safeAreaInsets;
        }
        self.backgroundView.frame = view.bounds;
        // 圆角
        self.cornerView.frame = CGRectMake(0, safeAreaInsets.top, self.backgroundView.bounds.size.width, self.backgroundView.bounds.size.height-safeAreaInsets.top-safeAreaInsets.bottom-34);
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.cornerView.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(8, 8)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.cornerView.bounds;
        maskLayer.path = maskPath.CGPath;
        self.cornerView.layer.mask = maskLayer;
    }
    
    CGSize imageSize = _imageView.image.size;

    CGSize textSize = [_titleLabel.text boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:_titleLabel.font, NSForegroundColorAttributeName:_titleLabel.textColor} context:nil].size;
    textSize.width = ceil(textSize.width)+1.0;
    
    CGFloat margin = 7.0;
    CGRect rect = self.control.frame;
    rect.size.height = self.frame.size.height;
    rect.size.width = textSize.width + margin*2.0;
    if (imageSize.width > 0) {
        rect.size.width += imageSize.width + margin;
    }
    
    self.frame = rect;
    self.control.hidden = (self.titleLabel.text.length == 0);
    
    self.control.frame = rect;
    // draw background
    CGRect controllBounds = CGRectInset(self.control.bounds, 0, 6);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:controllBounds cornerRadius:CGRectGetHeight(controllBounds)/2];
    if (self.shapeLayer == nil) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        self.control.layer.mask = shapeLayer;
        self.shapeLayer = shapeLayer;
    }
    self.shapeLayer.path = path.CGPath;
    
    CGRect titleLabelRect = CGRectMake(margin, (CGRectGetHeight(rect)-textSize.height)/2, textSize.width, textSize.height);
    
    self.imageView.frame = CGRectMake(CGRectGetMaxX(titleLabelRect)+margin, (CGRectGetHeight(rect)-imageSize.height)/2, imageSize.width, imageSize.height);
    CGRect imageViewBounds = self.imageView.bounds;
    UIBezierPath *imageViewPath = [UIBezierPath bezierPathWithRoundedRect:imageViewBounds cornerRadius:CGRectGetHeight(imageViewBounds)/2];
    if (self.imageViewShapeLayer == nil) {
        CAShapeLayer *imageViewShapeLayer = [CAShapeLayer layer];
        self.imageView.layer.mask = imageViewShapeLayer;
        self.imageViewShapeLayer = imageViewShapeLayer;
    }
    self.imageViewShapeLayer.path = imageViewPath.CGPath;
    
    CGFloat duration = self.enableAnimated ? 0.5 : 0.0;
    
    [self doAnimateWithDuration:duration animations:^{
        self.titleLabel.frame = titleLabelRect;
    } completion:^{
        self.enableAnimated = NO;
    }];
    
    
    
    
}

#pragma mark animated
- (void)doAnimateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(void))completion
{
    if (duration > 0) {
        [UIView animateWithDuration:duration animations:animations completion:^(BOOL finished) {
            if (completion) {
                completion();
            }
        }];
    } else {
        if (animations) {
            animations();
        }
        if (completion) {
            completion();
        }
    }
}

#pragma mark getCurrentVC
- (UIViewController *)getCurrentVC
{
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UIViewController *currentVC = [self getCurrentVCFrom:rootViewController];
    
    return currentVC;
}

- (UIViewController *)getCurrentVCFrom:(UIViewController *)rootVC
{
    UIViewController *currentVC = nil;
    
    if ([rootVC presentedViewController])
    {
        rootVC = [rootVC presentedViewController];
    }
    
    if ([rootVC isKindOfClass:[UITabBarController class]])
    {
        currentVC = [self getCurrentVCFrom:[(UITabBarController *)rootVC selectedViewController]];
        
    }
    else if ([rootVC isKindOfClass:[UINavigationController class]])
    {
        currentVC = [self getCurrentVCFrom:[(UINavigationController *)rootVC visibleViewController]];
        
    }
    else
    {
        currentVC = rootVC;
    }
    
    return currentVC;
}

@end
