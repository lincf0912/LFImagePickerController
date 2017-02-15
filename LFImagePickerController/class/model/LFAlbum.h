//
//  LFAlbum.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class LFAsset;
@interface LFAlbum : NSObject

@property (nonatomic, readonly) NSString *name;        ///< The album name
@property (nonatomic, readonly) NSInteger count;       ///< Count of photos the album contain
@property (nonatomic, readonly) id result;             ///< PHFetchResult<PHAsset> or ALAssetsGroup<ALAsset>

/** 缓存数据 */
@property (nonatomic, strong) NSArray <LFAsset *>*models;

- (instancetype)initWithName:(NSString *)name result:(id)result;

@end
