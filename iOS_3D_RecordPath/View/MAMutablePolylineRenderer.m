//
//  MAMutablePolylineView.m
//  test3D
//
//  Created by xiaoming han on 15/7/15.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import "MAMutablePolylineRenderer.h"

@implementation MAMutablePolylineRenderer

- (instancetype)initWithMutablePolyline:(MAMutablePolyline *)polyline
{
    self = [super initWithOverlay:polyline];
    if (self)
    {
        
    }
    return self;
}

- (MAMutablePolyline *)mutablePolyline
{
    return (MAMutablePolyline *)self.overlay;
}

#pragma mark - Override

- (void)referenceDidChange
{
    [super referenceDidChange];
    
    MAMutablePolyline *polyline = [self mutablePolyline];
    
    if (polyline.points == NULL || polyline.pointCount < 2)
    {
        return;
    }
    
    self.glPoints = [self glPointsForMapPoints:polyline.points count:polyline.pointCount];
    self.glPointCount = polyline.pointCount;
}

- (void)glRender
{
    if (self.glPoints == NULL || self.glPointCount < 2 || self.lineWidth <= 0.0)
    {
        return;
    }
    
    [self renderLinesWithPoints:self.glPoints
                         pointCount:self.glPointCount
                        strokeColor:self.strokeColor
                          lineWidth:[self glWidthForWindowWidth:self.lineWidth]
                             looped:NO
                       LineJoinType:self.lineJoinType
                        LineCapType:self.lineCapType
                           lineDash:self.lineDash];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
