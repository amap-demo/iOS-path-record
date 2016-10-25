//
//  MAMutablePolyline.m
//  test3D
//
//  Created by xiaoming han on 15/7/15.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "MAMutablePolyline.h"
#import <MAMapKit/MAGeometry.h>

@interface MAMutablePolyline ()
{
    MAMapRect _boundingRect;
    NSMutableArray *_pointArray;
}

@end

@implementation MAMutablePolyline

- (instancetype)initWithPoints:(NSArray *)points
{
    self = [super init];
    if (self)
    {
        [self updatePoints:points];
    }
    return self;
}

- (void)dealloc
{
    if (_points != NULL)
    {
        free(_points), _points = NULL;
    }
}

- (void)removeAllPoints
{
    [_pointArray removeAllObjects];
    [self calculateBoundingMapRect];
    [self buildPoints];
}

- (void)updatePoints:(NSArray *)points
{
    _pointArray = [NSMutableArray arrayWithArray:points];
    [self calculateBoundingMapRect];
    [self buildPoints];
}

- (void)appendPoint:(MAMapPoint)point
{
    [_pointArray addObject:[NSValue valueWithMAMapPoint:point]];
    [self calculateBoundingMapRect];
    [self buildPoints];
}

#pragma mark - Helper

- (void)buildPoints
{
    if (_points != NULL)
    {
        free(_points), _points = NULL;
    }
    
    _pointCount = _pointArray.count;
    
    if (_pointCount < 2)
    {
        NSLog(@"points count must greater than 2");
        return;
    }
    
    _points = (MAMapPoint *)malloc(_pointCount * sizeof(MAMapPoint));
    
    int i = 0;
    for (NSValue *value in _pointArray)
    {
        MAMapPoint point = [value MAMapPointValue];
        _points[i] = point;
        ++i;
    }
}

- (void)calculateBoundingMapRect
{
    if (_pointArray.count > 0)
    {
        CGFloat minX = 0;
        CGFloat minY = 0;
        CGFloat maxX = 0;
        CGFloat maxY = 0;
        
        int index = 0;
        for (NSValue *value in _pointArray)
        {
            if (index == 0)
            {
                MAMapPoint point0 = [value MAMapPointValue];
                minX = point0.x;
                minY = point0.y;
                maxX = minX;
                maxY = minY;
            }
            else
            {
                MAMapPoint point = [value MAMapPointValue];
                
                if (point.x < minX)
                {
                    minX = point.x;
                }
                
                if (point.x > maxX)
                {
                    maxX = point.x;
                }
                
                if (point.y < minY)
                {
                    minY = point.y;
                }
                
                if (point.y > maxY)
                {
                    maxY = point.y;
                }
            }
            ++index;
        }
        _boundingRect = MAMapRectMake(minX, minY, fabs(maxX - minX), fabs(maxY - minY));
        
    }
}

#pragma mark - MAOverlay

- (MAMapRect)boundingMapRect
{
    return _boundingRect;
}

- (CLLocationCoordinate2D)coordinate
{
    return MACoordinateForMapPoint(MAMapPointMake(MAMapRectGetMidX(_boundingRect), MAMapRectGetMidY(_boundingRect)));
}


@end
