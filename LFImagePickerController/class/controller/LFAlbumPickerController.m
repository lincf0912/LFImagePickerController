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

@interface LFAlbumPickerController ()<UITableViewDataSource,UITableViewDelegate> {
    UITableView *_tableView;
}
@property (nonatomic, strong) NSMutableArray *albumArr;

@end

@implementation LFAlbumPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:imagePickerVc.cancelBtnTitleStr style:UIBarButtonItemStylePlain target:imagePickerVc action:@selector(cancelButtonClick)];
    [self configTableView];
    // 采用微信的方式，只在相册列表页定义backBarButtonItem为返回，其余的顺系统的做法
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [imagePickerVc hideProgressHUD];
    
    [self configTableView];
    
    if (imagePickerVc.allowPickingImage) {
        self.navigationItem.title = @"相册";
    } else if (imagePickerVc.allowPickingVideo) {
        self.navigationItem.title = @"视频";
    }
}

- (void)configTableView {
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    [[LFAssetManager manager] getAllAlbums:imagePickerVc.allowPickingVideo allowPickingImage:imagePickerVc.allowPickingImage ascending:YES completion:^(NSArray<LFAlbum *> *models) {
        
        _albumArr = [NSMutableArray arrayWithArray:models];

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
            _tableView.rowHeight = 70;
            _tableView.tableFooterView = [[UIView alloc] init];
            _tableView.dataSource = self;
            _tableView.delegate = self;
            [_tableView registerClass:[LFAlbumCell class] forCellReuseIdentifier:@"LFAlbumCell"];
            [self.view addSubview:_tableView];
        } else {
            [_tableView reloadData];
        }
    }];
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LFAlbumCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LFAlbumCell"];
    LFImagePickerController *imagePickerVc = (LFImagePickerController *)self.navigationController;
    cell.selectedCountButton.backgroundColor = imagePickerVc.oKButtonTitleColorNormal;
    cell.model = _albumArr[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LFPhotoPickerController *photoPickerVc = [[LFPhotoPickerController alloc] init];
    photoPickerVc.columnNumber = self.columnNumber;
    LFAlbum *model = _albumArr[indexPath.row];
    photoPickerVc.model = model;
    [self.navigationController pushViewController:photoPickerVc animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
