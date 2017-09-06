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
 @param size image size
 @param duration Provides an estimate of the maximum duration of exported media
 @param loopCount loop count
 @param error error message
 @return image Data
 */
- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images
                               size:(CGSize)size
                           duration:(NSTimeInterval)duration
                          loopCount:(NSUInteger)loopCount
                              error:(NSError **)error;

/**
 Create Gif

 @param images The array must contain UIImages
 @param duration Provides an estimate of the maximum duration of exported media
 @param loopCount loop count
 @param error error message
 @return image Data
 */
- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images
                           duration:(NSTimeInterval)duration
                          loopCount:(NSUInteger)loopCount
                              error:(NSError **)error;

/**
 Create Gif
 
 @param images The array must contain UIImages
 @param size image size
 @param duration Provides an estimate of the maximum duration of exported media
 @param loopCount loop count
 @param error error message
 @return image
 */
- (UIImage *)createGifWithImages:(NSArray <UIImage *>*)images
                            size:(CGSize)size
                        duration:(NSTimeInterval)duration
                       loopCount:(NSUInteger)loopCount
                           error:(NSError **)error;

/**
 Create Gif
 
 @param images The array must contain UIImages
 @param duration Provides an estimate of the maximum duration of exported media
 @param loopCount loop count
 @param error error message
 @return image
 */
- (UIImage *)createGifWithImages:(NSArray <UIImage *>*)images
                        duration:(NSTimeInterval)duration
                       loopCount:(NSUInteger)loopCount
                           error:(NSError **)error;



/**
 Create MP4

 @param images The array must contain UIImages
 @param size Video image size
 @param fps The image frames per second (30.fps)
 @param duration Provides an estimate of the maximum duration of exported media
 @param audioPath Background music
 @param complete data and error message
 */
- (void)createMP4WithImages:(NSArray <UIImage *>*)images
                       size:(CGSize)size
                        fps:(NSUInteger)fps
                   duration:(NSTimeInterval)duration
                  audioPath:(NSString *)audioPath
                   complete:(void (^)(NSData *data, NSError *error))complete;

/**
 Create MP4
 
 @param images The array must contain UIImages
 @param size Video image size
 @param audioPath Background music
 @param complete data and error message
 */
- (void)createMP4WithImages:(NSArray <UIImage *>*)images
                       size:(CGSize)size
                  audioPath:(NSString *)audioPath
                   complete:(void (^)(NSData *data, NSError *error))complete;

/**
 Create MP4
 
 @param images The array must contain UIImages
 @param size Video image size
 @param complete data and error message
 */
- (void)createMP4WithImages:(NSArray <UIImage *>*)images
                       size:(CGSize)size
                   complete:(void (^)(NSData *data, NSError *error))complete;

@end
