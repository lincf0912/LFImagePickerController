//
//  LFAssetManager+CreateMedia.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/9/5.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAssetManager+CreateMedia.h"
#import <MobileCoreServices/UTCoreTypes.h>

NSString *const CreateMediaFolder = @"LFAssetManager.CreateMedia";

@implementation LFAssetManager (CreateMedia)

- (NSString *)myMediaFolder
{
    NSString *tmpDir = NSTemporaryDirectory();
    NSString *path = [tmpDir stringByAppendingPathComponent:CreateMediaFolder];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExists = [fileManager fileExistsAtPath:path];
    if (isExists == NO) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (NSData *)createGifDataWithImages:(NSArray <UIImage *>*)images duration:(NSTimeInterval)duration loopCount:(NSUInteger)loopCount error:(NSError **)error
{
    if (images.count == 0) return nil;
    
    NSDictionary *userInfo = nil;
    {
        size_t frameCount = images.count;
        NSTimeInterval frameDuration = (duration / frameCount);
        NSDictionary *frameProperties = @{
                                          (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                  (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDuration)
                                                  }
                                          };
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
        
        NSDictionary *imageProperties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                   (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)
                                                   }
                                           };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
        
        for (size_t idx = 0; idx < images.count; idx++) {
            CGImageDestinationAddImage(destination, [[images objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            
            *error = [[NSError alloc] initWithDomain:@"LFAssetManager.CreateMedia.gif.error" code:-1 userInfo:userInfo];
            return nil;
        }
        
        return [NSData dataWithData:mutableData];
    }
}

@end
