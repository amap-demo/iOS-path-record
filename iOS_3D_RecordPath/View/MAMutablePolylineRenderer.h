//
//  MAMutablePolylineView.h
//  test3D
//
//  Created by xiaoming han on 15/7/15.
//  Copyright (c) 2015年 AutoNavi. All rights reserved.
//

#import <MAMapKit/MAOverlayPathRenderer.h>
#import "MAMutablePolyline.h"

@interface MAMutablePolylineRenderer : MAOverlayPathRenderer

@property (nonatomic, readonly) MAMutablePolyline *mutablePolyline;

- (instancetype)initWithMutablePolyline:(MAMutablePolyline *)polyline;

@end
