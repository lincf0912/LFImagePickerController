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

@interface PHAsset (LFRealDuration)

- (NSTimeInterval)lf_getRealDuration;

@end

@implementation PHAsset (LFRealDuration)

- (NSTimeInterval)lf_getRealDuration
{
    __block double dur = 0;
    /** 为了更加快速的获取相册数据，非慢动作视频不使用requestAVAssetForVideo获取时长。直接获取duration属性即可 */
    if (self.mediaSubtypes == PHAssetMediaSubtypeVideoHighFrameRate) {
        /** 慢动作视频获取真实时长 */
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version =  PHVideoRequestOptionsVersionCurrent;
        //        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        /** requestAVAssetForVideo api可以获取AVAsset，里面的duration可以转换为真实时长，此方法并不太耗时。 */
//        NSTimeInterval s = [[NSDate date] timeIntervalSince1970];
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:self options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            dur = CMTimeGetSeconds(urlAsset.duration);
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
//        NSLog(@"time : %f", [[NSDate date] timeIntervalSince1970] - s);
    }
    if (!isnan(dur) && dur>0) {
        return dur;
    }
    return self.duration;
}

@end

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
                _duration = [phAsset lf_getRealDuration];
            } else if (phAsset.mediaType == PHAssetMediaTypeImage) {
#ifdef __IPHONE_9_1
                if (phAsset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                    _subType = LFAssetSubMediaTypeLivePhoto;
                } else
#endif
                /** 判断gif图片，由于公开方法效率太低，改用私有API判断 */
                    if ([[phAsset valueForKey:@"uniformTypeIdentifier"] isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                        _subType = LFAssetSubMediaTypeGIF;
                    }
                //                if (@available(iOS 9.0, *)){
                //                    /** 新判断GIF图片方法 */
                //                    NSArray <PHAssetResource *>*resourceList = [PHAssetResource assetResourcesForAsset:asset];
                //                    [resourceList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                //                        PHAssetResource *resource = obj;
                //                        if ([resource.uniformTypeIdentifier isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                //                            self->_subType = LFAssetSubMediaTypeGIF;
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
                //                                                                        self->_subType = LFAssetSubMediaTypeGIF
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
