
//
//  DisplayViewController.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "DisplayViewController.h"
#import "MAMutablePolylineRenderer.h"
#import "AMapRouteRecord.h"
#import "MovingAnnotationView.h"
#import "TracingPoint.h"
#import "Util.h"

@interface DisplayViewController()<MAMapViewDelegate, MovingAnnotationViewDelegate>
{
    NSMutableArray *_tracking;
    CFTimeInterval _duration;
}

@property (nonatomic, strong) AMapRouteRecord *record;

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) MAPointAnnotation *myLocation;

@property (nonatomic, assign) BOOL isPlaying;

@end


@implementation DisplayViewController


#pragma mark - Utility

- (void)showRoute
{
    if (self.record == nil || [self.record numOfLocations] == 0)
    {
        NSLog(@"invaled route");
    }
    
    [self initDisplayRoutePolyline];

    [self initDisplayTrackingCoords];
}

#pragma mark - Interface

- (void)setRecord:(AMapRouteRecord *)record
{
    if (_record == record)
    {
        return;
    }
    
    if (self.isPlaying)
    {
        [self actionPlayAndStop];
    }
    
    _record = record;
    _duration = _record.totalDuration / 1.0;
}

#pragma mark - movingAnnotationViewDelegate

- (void)didMovingAnnotationStop:(MovingAnnotationView *)view
{
    if (self.isPlaying)
    {
        [self actionPlayAndStop];
    }
}

#pragma mark - mapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if([annotation isEqual:self.myLocation]) {
        
        static NSString *annotationIdentifier = @"myLcoationIdentifier";
        
        MovingAnnotationView *annotationView = (MovingAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (annotationView == nil)
        {
            annotationView = [[MovingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        
        annotationView.image = [UIImage imageNamed:@"car"];
        annotationView.canShowCallout = NO;
        
        return annotationView;
    }
    
    if ([annotation isKindOfClass:[MAPointAnnotation class]])
    {
        static NSString *annotationIdentifier = @"lcoationIdentifier";
        
        MAPinAnnotationView *poiAnnotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        
        if (poiAnnotationView == nil)
        {
            poiAnnotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        }
        poiAnnotationView.pinColor = MAPinAnnotationColorGreen;
        poiAnnotationView.canShowCallout = YES;
        
        return poiAnnotationView;
    }
    
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *view = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        view.lineWidth = 4.0;
        view.strokeColor = [UIColor redColor];
        
        return view;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view
{
    if (view.annotation == self.myLocation)
    {
        [mapView selectAnnotation:self.myLocation animated:NO];
    }
}

#pragma mark - Action

- (void)actionPlayAndStop
{
    if (self.record == nil)
    {
        return;
    }
    
    self.isPlaying = !self.isPlaying;
    if (self.isPlaying)
    {
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"icon_stop.png"];
        if (self.myLocation == nil)
        {
            self.myLocation = [[MAPointAnnotation alloc] init];
            self.myLocation.title = @"AMap";
            self.myLocation.coordinate = [self.record startLocation].coordinate;
            
            [self.mapView addAnnotation:self.myLocation];
            
            // 选中myLocation，不会被重用移除。
            [self.mapView selectAnnotation:self.myLocation animated:NO];
        }
        
        MovingAnnotationView * carView = (MovingAnnotationView *)[self.mapView viewForAnnotation:self.myLocation];
        carView.mapView = self.mapView;
        carView.animationDelegate = self;
        [carView addTrackingAnimationIgnoringCourseForPoints:_tracking duration:_duration];

    }
    else
    {
        self.navigationItem.rightBarButtonItem.image = [UIImage imageNamed:@"icon_play.png"];
        
        MAAnnotationView *view = [self.mapView viewForAnnotation:self.myLocation];
        if (view != nil)
        {
            [view.layer removeAllAnimations];
        }
    }
}

#pragma mark - Initialazation

- (void)initToolBar
{
    UIBarButtonItem *playItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_play.png"] style:UIBarButtonItemStylePlain target:self action:@selector(actionPlayAndStop)];
    self.navigationItem.rightBarButtonItem = playItem;
}

- (void)initMapView
{
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.mapView.delegate = self;
    self.mapView.showsIndoorMap = NO;
    [self.view addSubview:self.mapView];
}

- (void)initDisplayRoutePolyline
{
    NSArray<MATracePoint *> *tracePoints = self.record.tracedLocations;
    
    if (tracePoints.count < 2)
    {
        return;
    }
    
    MAPointAnnotation *startPoint = [[MAPointAnnotation alloc] init];
    startPoint.coordinate = CLLocationCoordinate2DMake(tracePoints.firstObject.latitude, tracePoints.firstObject.longitude);
    startPoint.title = @"start";
    [self.mapView addAnnotation:startPoint];
    
    MAPointAnnotation *endPoint = [[MAPointAnnotation alloc] init];
    endPoint.coordinate = CLLocationCoordinate2DMake(tracePoints.lastObject.latitude, tracePoints.lastObject.longitude);
    endPoint.title = @"end";
    [self.mapView addAnnotation:endPoint];
    
    CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(tracePoints.count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < tracePoints.count; i++)
    {
        coords[i] = CLLocationCoordinate2DMake(tracePoints[i].latitude, tracePoints[i].longitude);
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coords count:tracePoints.count];
    [self.mapView addOverlay:polyline];
    
    [self.mapView showOverlays:self.mapView.overlays edgePadding:UIEdgeInsetsMake(30, 50, 30, 50) animated:NO];
    
    if (coords)
    {
        free(coords);
    }

}

- (void)initDisplayTrackingCoords
{
    NSArray<MATracePoint *> *points = self.record.tracedLocations;
    
    if (points.count < 2)
    {
        return;
    }
    
    _tracking = [NSMutableArray array];
    for (int i = 0; i < points.count - 1; i++)
    {
        TracingPoint * tp = [[TracingPoint alloc] init];
        tp.coordinate = CLLocationCoordinate2DMake(points[i].latitude, points[i].longitude);
//        tp.course = [Util calculateCourseFromCoordinate:CLLocationCoordinate2DMake(points[i].latitude, points[i].longitude) to:CLLocationCoordinate2DMake(points[i+1].latitude, points[i+1].longitude)];
        
        NSLog(@"tp.course :%f", tp.course);
        [_tracking addObject:tp];
    }
    
    TracingPoint *lastTp = [[TracingPoint alloc] init];
    lastTp.coordinate = CLLocationCoordinate2DMake(points.lastObject.latitude, points.lastObject.longitude);
    lastTp.course = ((TracingPoint *)[_tracking lastObject]).course;
    [_tracking addObject:lastTp];
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Display";
    
    [self initMapView];
    
    [self initToolBar];
    
    [self showRoute];
}

@end
