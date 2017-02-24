//
//  LF_FileUtility.h
//  LFImagePickerController
//
//  Created by LamTsanFeng on 2017/2/9.
//  Copyright © 2017年 Miracle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LF_FileUtility : NSObject

+ (BOOL)createFile:(NSString *)path;
+ (BOOL)createFolder:(NSString *)path errStr:(NSString **)errStr;
+ (BOOL)fileExist:(NSString *)path;
+ (BOOL)directoryExist:(NSString *)path;
+ (BOOL)moveFileAtPath:(NSString *)atPath toPath:(NSString *)toPath;
+ (BOOL)copyFileAtPath:(NSString *)atPath toPath:(NSString *)toPath;
+ (BOOL)removeFile:(NSString *)path;
+ (void)writeLogToFile:(NSString *)filePath appendTxt:(NSString *)txt;
+ (u_int64_t)fileSizeForPath:(NSString *)path;
+ (NSArray *)findFile:(NSString *)path;

/**
 *  根据文件大小返回文件大小字符串
 *
 *  @param aSize 文件大小，单位B
 *
 *  @return 文件大小字符串
 */
+ (NSString*)getFileSizeString:(float)aSize;
@end
