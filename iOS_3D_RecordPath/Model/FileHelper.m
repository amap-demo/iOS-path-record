
//
//  FileHelper.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "FileHelper.h"
#import "AMapRouteRecord.h"

@implementation FileHelper

+ (NSArray *)recordsArray
{
    NSString *path = [FileHelper baseDir];
    
    NSError *error = nil;
    NSArray *fileArray = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if (error!=nil)
    {
        return nil;
    }
    else
    {
        NSMutableArray *records = [[NSMutableArray alloc] init];
        for (NSString *fileName in fileArray)
        {
            NSString *recordPath = [path stringByAppendingPathComponent:fileName];
            
            @try {
                AMapRouteRecord *record = [NSKeyedUnarchiver unarchiveObjectWithFile:recordPath];
                [records addObject:record];
                
            } @catch (NSException *exception) {
                NSLog(@"exception :%@", exception);
                [[NSFileManager defaultManager] removeItemAtPath:recordPath error:nil];
                
            } @finally {
                
            }
            
        }
        return [records copy];
    }
}

+ (NSString *)baseDir
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    path = [path stringByAppendingPathComponent:@"pathRecords"];
    
    return path;
}

+ (NSString *)filePathWithName:(NSString *)name
{
    NSString *path = [FileHelper baseDir];
    
    BOOL pathSuccess = [[NSFileManager defaultManager] fileExistsAtPath:path];
    
    if (! pathSuccess)
    {
        pathSuccess = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *documentPath = [path stringByAppendingPathComponent:name];
    
    return documentPath;
}

+ (BOOL)deleteFile:(NSString *)filename
{
    NSString *path = [FileHelper filePathWithName:filename];
    
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (error != nil)
    {
        NSLog(@"%@",error);
    }
    
    return success;
}



@end
