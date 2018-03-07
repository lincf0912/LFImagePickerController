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

@end

@implementation LFAsset

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
                if (iOS9_1Later && phAsset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
                    _subType = LFAssetSubMediaTypeLivePhoto;
                } else
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
            PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
            option.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                _bytes = imageData.length;
            }];
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
            _bytes = (NSInteger)assetRep.size;
        }
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [self initWithAsset:nil];
    if (self) {
        _type = LFAssetMediaTypePhoto;
        _previewImage = image;
        _subType = image.images.count ? LFAssetSubMediaTypeGIF : LFAssetSubMediaTypeNone;
    }
    return self;
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
        if ([self.previewImage isEqual:objAsset.previewImage]) {
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
    if (self.previewImage) {
        assetHash ^= [self.previewImage hash];
    }
    return assetHash;
}

@end
