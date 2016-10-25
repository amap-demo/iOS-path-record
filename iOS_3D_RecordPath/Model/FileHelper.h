//
//  FileHelper.h
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FileHelper : NSObject

+ (NSString *)filePathWithName:(NSString *)name;

+ (NSMutableArray *)recordsArray;

+ (BOOL)deleteFile:(NSString *)filename;

@end
