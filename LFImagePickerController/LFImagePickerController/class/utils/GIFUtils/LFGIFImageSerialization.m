//
//  LFGIFImageSerialization.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/5/17.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFGIFImageSerialization.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>

NSString * const LF_AnimatedGIFImageErrorDomain = @"com.compuserve.gif.image.error";

__attribute__((overloadable)) NSData * LF_UIImageGIFRepresentation(UIImage *image) {
    return LF_UIImageGIFRepresentation(image, 0.0f, 0, nil);
}

__attribute__((overloadable)) NSData * LF_UIImageGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error) {
    if (!image.images) {
        return nil;
    }
    
    NSDictionary *userInfo = nil;
    {
        size_t frameCount = image.images.count;
        NSTimeInterval frameDuration = (duration <= 0.0 ? image.duration / frameCount : duration / frameCount);
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
        
        for (size_t idx = 0; idx < image.images.count; idx++) {
            CGImageDestinationAddImage(destination, [[image.images objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            
            goto _error;
        }
        
        return [NSData dataWithData:mutableData];
    }
_error: {
    if (error) {
        *error = [[NSError alloc] initWithDomain:LF_AnimatedGIFImageErrorDomain code:-1 userInfo:userInfo];
    }
    
    return nil;
}
}

__attribute__((overloadable)) NSData * LF_UIImagePNGRepresentation(UIImage *image, CGFloat compressionQuality) {
    return LF_UIImageRepresentation(image, compressionQuality, kUTTypePNG, nil);
}

__attribute__((overloadable)) NSData * LF_UIImageJPEGRepresentation(UIImage *image, CGFloat compressionQuality) {
    return LF_UIImageRepresentation(image, compressionQuality, kUTTypeJPEG, nil);
}

__attribute__((overloadable)) NSData * LF_UIImageRepresentation(UIImage *image, CGFloat compressionQuality, CFStringRef __nonnull type, NSError * __autoreleasing *error) {
    
    if (!image) {
        return nil;
    }
    NSDictionary *userInfo = nil;
    {
        NSDictionary *frameProperties = nil;
        
        frameProperties = @{
                            (__bridge NSString *)kCGImageDestinationLossyCompressionQuality: @(MIN(MAX(compressionQuality, 0), 1))
                            };
        
        NSMutableData *mutableData = [NSMutableData data];
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, type, 1, NULL);
        
        if (frameProperties) {
            CGImageDestinationAddImage(destination, [image CGImage], (__bridge CFDictionaryRef)frameProperties);
        } else {
            CGImageDestinationAddImage(destination, [image CGImage], NULL);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            
            goto _error;
        }
        
        return [NSData dataWithData:mutableData];
    }
_error: {
    if (error) {
        *error = [[NSError alloc] initWithDomain:LF_AnimatedGIFImageErrorDomain code:-1 userInfo:userInfo];
    }
    
    return nil;
}
}
