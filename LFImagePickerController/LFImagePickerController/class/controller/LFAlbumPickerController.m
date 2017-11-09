//
//  LFAlbumPickerController.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAlbumPickerController.h"
#import "LFImagePickerController.h"
#import "LFPhotoPickerController.h"
#import "LFImagePickerHeader.h"
#import "UIView+LFFrame.h"
#import "LFAssetManager+Authorization.h"
#import "LFAlbumCell.h"

#ifdef LF_MEDIAEDIT
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"
#endif

@interface LFAlbumPickerController ()<UITableViewDataSource,UITableViewDelegate,PHPhotoLibraryChangeObserver> {
    UITableView *_tableView;
}
@property (nonatomic, strong) NSMutableArray *albumArr;

@end

@implementation LFAlbumPickerController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 采用微信的方式，只在相册列表页定义backBarButtonItem为返回，其余的顺系统的做法
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self configTableView];
    
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (imagePickerVc.syncAlbum) {
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];    //创建监听者
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _tableView.frame = [self viewFrameWithoutNavigation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
    /** 移除数据源 */
    [imagePickerVc.selectedModels removeAllObjects];
    /** 恢复原图 */
    imagePickerVc.isSelectOriginalPhoto = NO;

#ifdef LF_MEDIAEDIT
    if (imagePickerVc.allowEditing || imagePickerVc.syncAlbum) {
        [_tableView reloadData];
    }
#else
    if (imagePickerVc.syncAlbum) {
        [_tableView reloadData];
    }
#endif
}

- (void)dealloc
{
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    if (imagePickerVc.syncAlbum) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];    //移除监听者
    }
}

- (void)configTableView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LFAssetManager manager] getAllAlbums:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage ascending:imagePickerVc.sortAscendingByCreateDate completion:^(NSArray<LFAlbum *> *models) {
            
            _albumArr = [NSMutableArray arrayWithArray:models];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [imagePickerVc hideProgressHUD];
                if (!_tableView) {
                    _tableView = [[UITableView alloc] initWithFrame:[self viewFrameWithoutNavigation] style:UITableViewStylePlain];
                    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    _tableView.tableFooterView = [[UIView alloc] init];
                    _tableView.dataSource = self;
                    _tableView.delegate = self;
                    [_tableView registerClass:[LFAlbumCell class] forCellReuseIdentifier:@"LFAlbumCell"];
                    /** 这个设置iOS9以后才有，主要针对iPad，不设置的话，分割线左侧空出很多 */
                    if ([_tableView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
                        _tableView.cellLayoutMarginsFollowReadableWidth = NO;
                    }
                    [self.view addSubview:_tableView];
                } else {
                    [_tableView reloadData];
                }
            });
        }];
    });
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LFAlbumCell"];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    LFAlbum *album = _albumArr[indexPath.row];
    cell.model = album;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (album.count) {
        if (album.posterAsset == nil) { /** 没有缓存数据 */
            NSInteger index = 0;
            if (imagePickerVc.sortAscendingByCreateDate) {
                index = album.count-1;
            }
            [[LFAssetManager manager] getAssetFromFetchResult:album.result
                                                      atIndex:index
                                            allowPickingVideo:imagePickerVc.allowPickingVideo
                                            allowPickingImage:imagePickerVc.allowPickingImage
                                                    ascending:imagePickerVc.sortAscendingByCreateDate
                                                   completion:^(LFAsset *model) {
                                                       
                                                       if ([cell.model isEqual:album]) {
                                                           cell.model.posterAsset = model;
                                                           [self setCellPosterImage:cell];
                                                       }
                                                   }];
        } else {
            [self setCellPosterImage:cell];
        }
    } else {
        cell.posterImage = bundleImageNamed(@"album_list_img_default");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LFPhotoPickerController *photoPickerVc = [[LFPhotoPickerController alloc] init];
    LFAlbum *model = _albumArr[indexPath.row];
    photoPickerVc.model = model;
    [self.navigationController pushViewController:photoPickerVc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [LFAlbumCell cellHeight];
}


#pragma mark - 设置封面
- (void)setCellPosterImage:(LFAlbumCell *)cell
{
    LFAsset *model = cell.model.posterAsset;
#ifdef LF_MEDIAEDIT
    /** 优先显示编辑图片 */
    LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
    if (photoEdit.editPosterImage) {
        cell.posterImage = photoEdit.editPosterImage;
    } else {
#endif
        [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if ([cell.model.posterAsset isEqual:model]) {
                cell.posterImage = photo;
            }
            
        } progressHandler:nil networkAccessAllowed:NO];
#ifdef LF_MEDIAEDIT
    }
#endif
}

#pragma mark - PHPhotoLibraryChangeObserver
//相册变化回调
- (void)photoLibraryDidChange:(PHChange *)changeInfo {
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        
        for (NSInteger i=0; i<self.albumArr.count; i++) {
            LFAlbum *album = self.albumArr[i];
            PHObjectChangeDetails *albumChanges = [changeInfo changeDetailsForObject:album.album];
            if (albumChanges) {
                // Fetch the new album and update the UI accordingly.
                [album changedAlbum:[albumChanges objectAfterChanges]];
                if (albumChanges.objectWasDeleted) {
                    [self.albumArr removeObjectAtIndex:i];
                    i--;
                }
            }
        }
        [_tableView reloadData];
    });
}
@end
