//
//  LFAsset.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/13.
//  Copyright © 2017年 LamTsanFeng. All rights reserved.
//

#import "LFAsset.h"

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "LFImagePickerHeader.h"

@interface LFAsset ()

@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, assign) NSInteger bytes;

@end

@implementation LFAsset

@synthesize bytes = _bytes;

- (instancetype)initWithAsset:(id)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        _type = LFAssetMediaTypePhoto;
        _duration = 0;
        _name = nil;
        
        if ([asset isKindOfClass:[PHAsset class]]) {
            PHAsset *phAsset = (PHAsset *)asset;
            _identifier = phAsset.localIdentifier;
            _name = [asset valueForKey:@"filename"];
            if (phAsset.mediaType == PHAssetMediaTypeVideo) {
                _type = LFAssetMediaTypeVideo;
                _duration = phAsset.duration;
            } else if (phAsset.mediaType == PHAssetMediaTypeImage) {
#ifdef __IPHONE_9_1
                if (phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                    _subType = LFAssetSubMediaTypeLivePhoto;
                } else
#endif
                /** 判断gif图片，由于公开方法效率太低，改用私有API判断 */
                    if ([[phAsset valueForKey:@"uniformTypeIdentifier"] isEqualToString:@"com.compuserve.gif"]) {
                        _subType = LFAssetSubMediaTypeGIF;
                    }
                //                if (iOS9_1Later) {
                //                    /** 新判断GIF图片方法 */
                //                    NSArray <PHAssetResource *>*resourceList = [PHAssetResource assetResourcesForAsset:asset];
                //                    [resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //                        PHAssetResource *resource = obj;
                //                        if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]) {
                //                            type = LFAssetMediaTypeGIF;
                //                            *stop = YES;
                //                        }
                //                    }];
                //                } else {
                //
                //                    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
                //                    option.resizeMode = PHImageRequestOptionsResizeModeFast;
                //                    option.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
                //                    option.synchronous = YES;
                //                    [[PHImageManager defaultManager] requestImageDataForAsset:asset
                //                                                                      options:option
                //                                                                resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                //                                                                    //gif 图片
                //                                                                    if ([dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                //                                                                        type = LFAssetMediaTypeGIF;
                //                                                                    }
                //                                                                }];
                //                }
            }
        } else if ([asset isKindOfClass:[ALAsset class]]) {
            ALAsset *alAsset = (ALAsset *)asset;
            ALAssetRepresentation *assetRep = [alAsset defaultRepresentation];
            NSURL *url = [asset valueForProperty:ALAssetPropertyURLs];
            _identifier = url.absoluteString;
            _name = assetRep.filename;
            /// Allow picking video
            if ([[alAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                _type = LFAssetMediaTypeVideo;
                _duration = [[alAsset valueForProperty:ALAssetPropertyDuration] integerValue];
            } else {
                ALAssetRepresentation *re = [alAsset representationForUTI: (__bridge NSString *)kUTTypeGIF];
                if (re) _subType = LFAssetSubMediaTypeGIF;
            }
            
        }
    }
    return self;
}

- (NSInteger)bytes
{
    return _bytes;
}

- (void)setBytes:(NSInteger)bytes
{
    _bytes = bytes;
}

#pragma mark - private
- (BOOL)isEqual:(id)object
{
    if([self class] == [object class])
    {
        if (self == object) {
            return YES;
        }
        LFAsset *objAsset = (LFAsset *)object;
        if ([self.asset isEqual: objAsset.asset]) {
            return YES;
        }
        if (!self.identifier && !objAsset.identifier && [self.identifier isEqualToString: objAsset.identifier]) {
            return YES;
        }
        return NO;
    }
    else
    {
        return [super isEqual:object];
    }
}

- (NSUInteger)hash
{
    NSUInteger assetHash = 0;
    if (self.asset) {
        assetHash ^= [self.asset hash];
    }
    if (self.identifier) {
        assetHash ^= [self.identifier hash];
    }
    return assetHash;
}

@end

@implementation LFAsset (preview)

- (UIImage *)thumbnailImage
{
    if ([self.asset conformsToProtocol:@protocol(LFAssetImageProtocol)]) {
        id <LFAssetImageProtocol> imageAsset = self.asset;
        return imageAsset.assetImage;
    }
    else if ([self.asset conformsToProtocol:@protocol(LFAssetPhotoProtocol)]) {
        id <LFAssetPhotoProtocol> photoAsset = self.asset;
        return photoAsset.thumbnailImage;
    }
    else if ([self.asset conformsToProtocol:@protocol(LFAssetVideoProtocol)]) {
        id <LFAssetVideoProtocol> videoAsset = self.asset;
        return videoAsset.thumbnailImage;
    }
    return nil;
}

- (UIImage *)previewImage
{
    if ([self.asset conformsToProtocol:@protocol(LFAssetImageProtocol)]) {
        id <LFAssetImageProtocol> imageAsset = self.asset;
        return imageAsset.assetImage;
    }
    else if ([self.asset conformsToProtocol:@protocol(LFAssetPhotoProtocol)]) {
        id <LFAssetPhotoProtocol> photoAsset = self.asset;
        return photoAsset.originalImage;
    }
    else if ([self.asset conformsToProtocol:@protocol(LFAssetVideoProtocol)]) {
        id <LFAssetVideoProtocol> videoAsset = self.asset;
        return videoAsset.thumbnailImage;
    }
    return nil;
}

- (NSURL *)previewVideoUrl
{
    if ([self.asset conformsToProtocol:@protocol(LFAssetVideoProtocol)]) {
        id <LFAssetVideoProtocol> videoAsset = self.asset;
        return videoAsset.videoUrl;
    }
    return nil;
}

- (instancetype)initWithImage:(UIImage *)image __deprecated_msg("Method deprecated. Use `initWithObject:`")
{
    self = [self initWithAsset:nil];
    if (self) {
        _subType = image.images.count ? LFAssetSubMediaTypeGIF : LFAssetSubMediaTypeNone;
    }
    return self;
}

- (instancetype)initWithObject:(id/* <LFAssetImageProtocol/LFAssetPhotoProtocol/LFAssetVideoProtocol> */)asset
{
    self = [self initWithAsset:asset];
    if (self) {
        if ([asset conformsToProtocol:@protocol(LFAssetImageProtocol)]) {
            id <LFAssetImageProtocol> imageAsset = asset;
            _subType = imageAsset.assetImage.images.count ? LFAssetSubMediaTypeGIF : LFAssetSubMediaTypeNone;
            _name = [NSString stringWithFormat:@"%zd", [imageAsset.assetImage hash]];
        }
        else if ([asset conformsToProtocol:@protocol(LFAssetPhotoProtocol)]) {
            id <LFAssetPhotoProtocol> photoAsset = asset;
            _subType = photoAsset.originalImage.images.count ? LFAssetSubMediaTypeGIF : LFAssetSubMediaTypeNone;
            _name = photoAsset.name.length ? photoAsset.name : [NSString stringWithFormat:@"%zd", [photoAsset.originalImage hash]];
        }
        else if ([asset conformsToProtocol:@protocol(LFAssetVideoProtocol)]) {
            id <LFAssetVideoProtocol> videoAsset = asset;
            _type = LFAssetMediaTypeVideo;
            NSDictionary *opts = [NSDictionary dictionaryWithObject:@(NO)
                                                             forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoAsset.videoUrl options:opts];
            _duration = CMTimeGetSeconds(asset.duration);
            _name = videoAsset.name.length ? videoAsset.name : [NSString stringWithFormat:@"%zd", [videoAsset.videoUrl hash]];
        }
        
    }
    return self;
}

@end
