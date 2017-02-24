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
#import "LFPhotoEditManager.h"
#import "LFPhotoEdit.h"

@interface LFAlbumPickerController ()<UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
}
@property (nonatomic, strong) NSMutableArray *albumArr;

@end

@implementation LFAlbumPickerController

- (void)setReplaceModel:(LFAlbum *)replaceModel
{
    _replaceModel = replaceModel;
    if (_albumArr && _replaceModel) {
        for (NSInteger i=0; i<_albumArr.count; i++) {
            LFAlbum *model = _albumArr[i];
            if ([model.name isEqualToString:_replaceModel.name]) {
                [_albumArr replaceObjectAtIndex:i withObject:_replaceModel];
                _replaceModel = nil;
                /** 刷新 */
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
}

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
    /** 移除数据源 */
    [imagePickerVc.selectedModels removeAllObjects];
    /** 恢复原图 */
    imagePickerVc.isSelectOriginalPhoto = NO;
    
    if (imagePickerVc.allowEditting) {
        [_tableView reloadData];
    }
}

- (void)configTableView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc showProgressHUD];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[LFAssetManager manager] getAllAlbums:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage ascending:imagePickerVc.sortAscendingByCreateDate completion:^(NSArray<LFAlbum *> *models) {
            
            _albumArr = [NSMutableArray arrayWithArray:models];
            if (_replaceModel) { /** 替换对象 */
                for (NSInteger i=0; i<_albumArr.count; i++) {
                    LFAlbum *model = _albumArr[i];
                    if ([model.name isEqualToString:_replaceModel.name]) {
                        [_albumArr replaceObjectAtIndex:i withObject:_replaceModel];
                        _replaceModel = nil;
                        break;
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [imagePickerVc hideProgressHUD];
                if (!_tableView) {
                    
                    CGFloat top = 0;
                    CGFloat tableViewHeight = 0;
                    if (self.navigationController.navigationBar.isTranslucent) {
                        top = 44;
                        if (iOS7Later) top += 20;
                        tableViewHeight = self.view.height - top;
                    } else {
                        CGFloat navigationHeight = 44;
                        if (iOS7Later) navigationHeight += 20;
                        tableViewHeight = self.view.height - navigationHeight;
                    }
                    
                    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, top, self.view.width, tableViewHeight) style:UITableViewStylePlain];
                    _tableView.tableFooterView = [[UIView alloc] init];
                    _tableView.dataSource = self;
                    _tableView.delegate = self;
                    [_tableView registerClass:[LFAlbumCell class] forCellReuseIdentifier:@"LFAlbumCell"];
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
    
    NSInteger index = 0;
    if (imagePickerVc.sortAscendingByCreateDate) {
        index = album.count-1;
    }
    [[LFAssetManager manager] getAssetFromFetchResult:album.result atIndex:index allowPickingVideo:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage completion:^(LFAsset *model) {
        /** 优先显示编辑图片 */
        LFPhotoEdit *photoEdit = [[LFPhotoEditManager manager] photoEditForAsset:model];
        if ([cell.model isEqual:album] && photoEdit.editPosterImage) {
            cell.posterImage = photoEdit.editPosterImage;
        } else {
            [[LFAssetManager manager] getPhotoWithAsset:model.asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                if ([cell.model isEqual:album]) {
                    cell.posterImage = photo;
                }
                
            } progressHandler:nil networkAccessAllowed:NO];
        }
    }];
    
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


@end
