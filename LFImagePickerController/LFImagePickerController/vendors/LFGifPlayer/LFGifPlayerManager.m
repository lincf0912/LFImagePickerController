//
//  GifUtils.m
//  MEMobile
//
//  Created by LamTsanFeng on 16/9/14.
//  Copyright © 2016年 GZMiracle. All rights reserved.
//

#import "LFGifPlayerManager.h"

#import "LFWeakProxy.h"

@interface GifSource : NSObject

@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSString *gifPath;
@property (nonatomic, strong) NSData *gifData;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, readonly) NSInteger frameCount;
@property (nonatomic, assign) CGFloat timestamp;
@property (nonatomic, assign) CGImageSourceRef gifSourceRef;

@property (nonatomic, copy) GifExecution execution;
@property (nonatomic, copy) GifFail fail;
@end

@implementation GifSource
@synthesize frameCount = _frameCount;

- (NSInteger)frameCount
{
    if (_frameCount == 0) {
        _frameCount = CGImageSourceGetCount(self.gifSourceRef);
    }
    return _frameCount;
}

@end


@interface LFGifPlayerManager ()

@property (nonatomic, strong) CADisplayLink     *displayLink;
@property (nonatomic, strong) NSMapTable        *gifSourceMapTable;

@end

@implementation LFGifPlayerManager

static LFGifPlayerManager *_sharedInstance = nil;
+ (LFGifPlayerManager *)shared{
    if (_sharedInstance == nil) {
        _sharedInstance = [[LFGifPlayerManager alloc] init];
    }
    return _sharedInstance;
}

+ (void)free
{
    [_sharedInstance stopDisplayLink];
    _sharedInstance = nil;
}

- (id)init{
    self = [super init];
    if (self) {
        _gifSourceMapTable = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory valueOptions:NSMapTableStrongMemory];
    }
    return self;
}

- (void)dealloc
{
    for (NSString *key in self.gifSourceMapTable) {
        GifSource *ref = [self.gifSourceMapTable objectForKey:key];
        if (ref) {
            if (ref.gifSourceRef) {
                CFRelease(ref.gifSourceRef);                
            }
            ref.execution = nil;
            ref.fail = nil;
            ref = nil;
        }
    }
    [_gifSourceMapTable removeAllObjects];
}

- (void)play{
    for (NSString *key in self.gifSourceMapTable) {
        GifSource *ref = [self.gifSourceMapTable objectForKey:key];
        [self playGif:ref];
    }
    
}

- (void)stopDisplayLink{
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
- (void)stopGIFWithKey:(NSString *)key
{
    GifSource *ref = [self.gifSourceMapTable objectForKey:key];
    if (ref) {
        [self.gifSourceMapTable removeObjectForKey:key];
        if (ref.gifSourceRef) {
            CFRelease(ref.gifSourceRef);
        }
        ref.execution = nil;
        ref.fail = nil;
        ref = nil;
    }

    if (_gifSourceMapTable.count<1 && _displayLink) {
        [self stopDisplayLink];
    }
}

- (BOOL)isGIFPlaying:(NSString *)key
{
    return (BOOL)[self.gifSourceMapTable objectForKey:key];
}

- (GifSource *)imageSourceCreateWithData:(id)data
{
    GifSource *gifSource = [GifSource new];
    if ([data isKindOfClass:[NSData class]]) {
        gifSource.gifSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)(data), NULL);
        gifSource.gifData = data;
    }else if ([data isKindOfClass:[NSString class]]) {
        gifSource.gifSourceRef = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:data], NULL);
        gifSource.gifPath = data;
    } else {
        gifSource = nil;
    }
    
    return gifSource;
}

- (void)transformGifPathToSampBufferRef:(NSString *)gifPath key:(NSString *)key execution:(GifExecution)executionBlock fail:(GifFail)failBlock
{
    [self transformGifToSampBufferRef:gifPath key:key execution:executionBlock fail:failBlock];
}

- (void)transformGifDataToSampBufferRef:(NSData *)gifData key:(NSString *)key execution:(GifExecution)executionBlock fail:(GifFail)failBlock
{
    [self transformGifToSampBufferRef:gifData key:key execution:executionBlock fail:failBlock];
}

- (void)transformGifToSampBufferRef:(id)data key:(NSString *)key execution:(GifExecution)executionBlock fail:(GifFail)failBlock
{
    if (key && data && executionBlock && failBlock) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            GifSource *existGifSource = [self.gifSourceMapTable objectForKey:key];
            if (!existGifSource) {
                GifSource *gifSource = [self imageSourceCreateWithData:data];
                gifSource.key = key;
                gifSource.execution = [executionBlock copy];
                gifSource.fail = [failBlock copy];
                if (!gifSource) {
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.gifSourceMapTable setObject:gifSource forKey:key];
                });
            } else {
                existGifSource.execution = [executionBlock copy];
                existGifSource.fail = [failBlock copy];
            }
        });
        if (!self.displayLink) {
            self.displayLink = [CADisplayLink displayLinkWithTarget:[LFWeakProxy proxyWithTarget:self] selector:@selector(play)];
            [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        }
    }
}


- (void)playGif:(GifSource *)gifSource
{
    size_t sizeMin = MIN(gifSource.index+1, gifSource.frameCount-1);
    if (sizeMin == SIZE_MAX) {
        //若该Gif文件无法解释为图片，需要立即返回避免内存crash
        gifSource.fail(gifSource.key);
        [self stopGIFWithKey:gifSource.key];
        return;
    }
    
    float nextFrameDuration = [self frameDurationAtIndex:sizeMin ref:gifSource.gifSourceRef];
    if (gifSource.timestamp < nextFrameDuration) {
        gifSource.timestamp = gifSource.timestamp+self.displayLink.duration;
        return;
    }
    gifSource.index += 1;
    gifSource.index = gifSource.index % gifSource.frameCount;
    CGImageSourceRef ref = gifSource.gifSourceRef;
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(ref, gifSource.index, NULL);
    
    gifSource.execution(imageRef, gifSource.key);
    
    CGImageRelease(imageRef);
    gifSource.timestamp = 0.f;
}

- (float)frameDurationAtIndex:(size_t)index ref:(CGImageSourceRef)ref
{
    CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(ref, index, NULL);
    NSDictionary *dict = (__bridge NSDictionary *)dictRef;
    NSDictionary *gifDict = (dict[(NSString *)kCGImagePropertyGIFDictionary]);
    NSNumber *unclampedDelayTime = gifDict[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    NSNumber *delayTime = gifDict[(NSString *)kCGImagePropertyGIFDelayTime];
    if (dictRef) CFRelease(dictRef);
    if (unclampedDelayTime.floatValue) {
        return unclampedDelayTime.floatValue;
    }else if (delayTime.floatValue) {
        return delayTime.floatValue;
    }else{
        return .1;
    }
}

@end
