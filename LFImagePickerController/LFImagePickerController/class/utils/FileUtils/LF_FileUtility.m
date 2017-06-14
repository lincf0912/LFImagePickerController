//
//  LF_FileUtility.m
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/9.
//  Copyright © 2017年 Miracle. All rights reserved.
//

#import "LF_FileUtility.h"

@implementation LF_FileUtility

+ (BOOL)createFolder:(NSString *)path errStr:(NSString **)errStr
{
    if (path.length == 0) return FALSE;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:path]) {
        
        if (![fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            if (errStr) (*errStr) = [error localizedDescription];
            NSLog(@"createFolder error: %@ \n",[error localizedDescription]);
            return FALSE;
        }
    }
    return TRUE;
}

+ (BOOL)createFile:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        
        return [fileManager createFileAtPath:path contents:nil attributes:nil];
    }
    return TRUE;
}

+ (BOOL)fileExist:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return ([fileManager fileExistsAtPath:path]);
}

+ (BOOL)directoryExist:(NSString *)path {
    BOOL isDirectory = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = ([fileManager fileExistsAtPath:path isDirectory:&isDirectory]);
    return (exist && isDirectory);
}

+ (BOOL)moveFileAtPath:(NSString *)atPath toPath:(NSString *)toPath{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (atPath.length > 0 && toPath.length > 0) {/** 如果文件路径为空就不操作 */
        NSError *error = nil;
        BOOL isOK = [fileManager moveItemAtPath:atPath toPath:toPath error:&error];
        if (error) {
            NSLog(@"moveFileAtPath error:%@", error.localizedDescription);
        }
        return isOK;
    } else {
        return NO;
    }
}

+ (BOOL)copyFileAtPath:(NSString *)atPath toPath:(NSString *)toPath{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (atPath.length > 0 && toPath.length > 0) {/** 如果文件路径为空就不复制 */
        return ([fileManager copyItemAtPath:atPath toPath:toPath error:nil]);
    }else{
        return NO;
    }
}

+ (BOOL)removeFile:(NSString *)path {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:path]) {
        return ([fileManager removeItemAtPath:path error:nil]);
    } else {
        return NO;
    }
}

+ (void)writeLogToFile:(NSString *)filePath appendTxt:(NSString *)txt {
    
    @synchronized(self) {
        NSDate *today = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *content = [NSString stringWithFormat:@"%@     _%@\n", [formatter stringFromDate:today], txt];
        NSData *contentData = [content dataUsingEncoding:NSUTF8StringEncoding];
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        if ([filemgr fileExistsAtPath: filePath ] == FALSE)
        {
            NSLog (@"File not found");
            [filemgr createFileAtPath:filePath contents:contentData attributes:nil];
            
        }else {
            
            NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
            if (myHandle == nil) {
                NSLog(@"Failed to open file");
                return;
            }
            [myHandle seekToEndOfFile];
            [myHandle writeData:contentData];
            [myHandle closeFile];
        }
    }
}

+ (u_int64_t)fileSizeForPath:(NSString *)path
{
    signed long long fileSize = 0;
    NSFileManager *fileManager = [NSFileManager new]; // default is not thread safe
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileSize = [fileDict fileSize];
        }
    }
    return fileSize;
}

+ (NSArray *)findFile:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:nil];
    return array;
}

/**
 *  根据文件大小返回文件大小字符串
 *
 *  @param aSize 文件大小，单位B
 *
 *  @return 文件大小字符串
 */
+ (NSString *)getFileSizeString:(float)aSize{
    NSArray *unitText = @[@"B",@"K",@"M",@"G",@"T"];
    NSInteger index = 0;
    while (aSize > 999) {
        index++;
        aSize /= 1024;
    }
    NSNumberFormatter *nFormat = [[NSNumberFormatter alloc] init];
    [nFormat setNumberStyle:NSNumberFormatterDecimalStyle];
    [nFormat setMaximumFractionDigits:1];
    return [NSString stringWithFormat:@"%@%@",[nFormat stringFromNumber:[NSNumber numberWithFloat:aSize]],[unitText objectAtIndex:index]];
}

@end
