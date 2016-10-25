//
//  MAMutablePolyline.h
//  test3D
//
//  Created by xiaoming han on 15/7/15.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAOverlay.h>

@interface MAMutablePolyline : NSObject<MAOverlay>


- (instancetype)initWithPoints:(NSArray *)points; // points 必须是NSValue

/// 坐标点数组
@property (nonatomic, readonly) MAMapPoint *points;

/// 坐标点的个数
@property (nonatomic, readonly) NSUInteger pointCount;


- (void)appendPoint:(MAMapPoint)point;

- (void)removeAllPoints;

@end
