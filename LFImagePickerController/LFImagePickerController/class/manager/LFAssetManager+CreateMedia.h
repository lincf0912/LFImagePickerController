//
//  LFAssetManager+CreateMedia.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/9/5.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager.h"

@interface LFAssetManager (CreateMedia)


/**
 Create Gif

 @param images The array must contain UIImages
 @param duration Provides an estimate of the maximum duration of exported media
 @param loopCount loop count
 @param error error message
 @return image Data
 */
- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error;

@end
