//
//  BaseMapViewController.m
//  SearchV3Demo
//
//  Created by songjian on 13-8-14.
//  Copyright (c) 2013年 songjian. All rights reserved.
//

#import "MainViewController.h"
#import "StatusView.h"
#import "TipView.h"
#import "AMapRouteRecord.h"
#import "FileHelper.h"
#import "RecordViewController.h"
#import "SystemInfoView.h"

#define kTempTraceLocationCount 20

@interface MainViewController()

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) MATraceManager *traceManager;


@property (nonatomic, strong) StatusView *statusView;
@property (nonatomic, strong) TipView *tipView;
@property (nonatomic, strong) UIButton *locationBtn;
@property (nonatomic, strong) UIImage *imageLocated;
@property (nonatomic, strong) UIImage *imageNotLocate;
@property (nonatomic, strong) SystemInfoView *systemInfoView;

@property (nonatomic, assign) BOOL isRecording;
@property (atomic, assign) BOOL isSaving;

@property (nonatomic, strong) MAPolyline *polyline;

@property (nonatomic, strong) NSMutableArray *locationsArray;

@property (nonatomic, strong) AMapRouteRecord *currentRecord;

@property (nonatomic, strong) NSMutableArray *tracedPolylines;
@property (nonatomic, strong) NSMutableArray *tempTraceLocations;
@property (nonatomic, assign) double totalTraceLength;

@end


@implementation MainViewController

#pragma mark - MapView Delegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if (!updatingLocation)
    {
        return;
    }
    
    if (!self.isRecording)
    {
        return;
    }
    
    if (userLocation.location.horizontalAccuracy < 100 && userLocation.location.horizontalAccuracy > 0)
    {
        double lastDis = [userLocation.location distanceFromLocation:self.currentRecord.endLocation];
        
        if (lastDis < 0.0 || lastDis > 10)
        {
            [self.locationsArray addObject:userLocation.location];
            
            //            NSLog(@"date: %@,now :%@",userLocation.location.timestamp, [NSDate date]);
            [self.tipView showTip:[NSString stringWithFormat:@"has got %ld locations",self.locationsArray.count]];
            
            [self.currentRecord addLocation:userLocation.location];
            
            if (self.polyline == nil)
            {
                self.polyline = [MAPolyline polylineWithCoordinates:NULL count:0];
                [self.mapView addOverlay:self.polyline];
            }

            NSUInteger count = 0;
            
            CLLocationCoordinate2D *coordinates = [self coordinatesFromLocationArray:self.locationsArray count:&count];
            if (coordinates != NULL)
            {
                [self.polyline setPolylineWithCoordinates:coordinates count:count];
                free(coordinates);
            }
            
            [self.mapView setCenterCoordinate:userLocation.location.coordinate animated:YES];
            
            
            // trace
            [self.tempTraceLocations addObject:userLocation.location];
            if (self.tempTraceLocations.count >= kTempTraceLocationCount)
            {
                [self queryTraceWithLocations:self.tempTraceLocations withSaving:NO];
                [self.tempTraceLocations removeAllObjects];
                
                // 把最后一个再add一遍，否则会有缝隙
                [self.tempTraceLocations addObject:userLocation.location];
            }
        }
    }
    
    [self.statusView showStatusWith:userLocation.location];
}

- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MAUserTrackingModeNone)
    {
        [self.locationBtn setImage:self.imageNotLocate forState:UIControlStateNormal];
    }
    else
    {
        [self.locationBtn setImage:self.imageLocated forState:UIControlStateNormal];
    }
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if (overlay == self.polyline)
    {
        MAPolylineRenderer *view = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        view.lineWidth = 5.0;
        view.strokeColor = [UIColor redColor];
        return view;
    }
    
    if ([overlay isKindOfClass:[MAPolyline class]])
    {
        MAPolylineRenderer *view = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        view.lineWidth = 10.0;
        view.strokeColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.8];
        return view;
    }
    
    return nil;
}

#pragma mark - Handle Action

- (void)actionRecordAndStop
{
    if (self.isSaving)
    {
        NSLog(@"保存结果中。。。");
        return;
    }
    
    self.isRecording = !self.isRecording;
    
    if (self.isRecording)
    {
        [self.tipView showTip:@"Start recording"];
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"icon_stop.png"];
        
        if (self.currentRecord == nil)
        {
            self.currentRecord = [[AMapRouteRecord alloc] init];
        }
        
        [self.mapView removeOverlays:self.tracedPolylines];
        [self setBackgroundModeEnable:YES];
    }
    else
    {
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"icon_play.png"];
        [self.tipView showTip:@"recording stoppod"];
        
        [self setBackgroundModeEnable:NO];
        
        [self actionSave];
    }
}

- (void)actionSave
{
    self.isRecording = NO;
    self.isSaving = YES;
    [self.locationsArray removeAllObjects];

    [self.mapView removeOverlay:self.polyline];
    self.polyline = nil;
    
    // 全程请求trace
    [self.mapView removeOverlays:self.tracedPolylines];
    [self queryTraceWithLocations:self.currentRecord.locations withSaving:YES];
}

- (void)actionLocation
{
    if (self.mapView.userTrackingMode == MAUserTrackingModeFollow)
    {
        [self.mapView setUserTrackingMode:MAUserTrackingModeNone];
    }
    else
    {
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
    }
}

- (void)actionShowList
{
    UIViewController *recordController = [[RecordViewController alloc] init];
    recordController.title = @"Records";
    
    [self.navigationController pushViewController:recordController animated:YES];
}

#pragma mark - Utility

- (CLLocationCoordinate2D *)coordinatesFromLocationArray:(NSArray *)locations count:(NSUInteger *)count
{
    if (locations.count == 0)
    {
        return NULL;
    }
    
    *count = locations.count;
    
    CLLocationCoordinate2D *coordinates = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * *count);
    
    int i = 0;
    for (CLLocation *location in locations)
    {
        coordinates[i] = location.coordinate;
        ++i;
    }
    
    return coordinates;
}

- (void)setBackgroundModeEnable:(BOOL)enable
{
    self.mapView.pausesLocationUpdatesAutomatically = !enable;
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0)
    {
        self.mapView.allowsBackgroundLocationUpdates = enable;
    }
}

- (void)queryTraceWithLocations:(NSArray<CLLocation *> *)locations withSaving:(BOOL)saving
{
    if (locations.count < 2) {
        return;
    }
    
    NSMutableArray *mArr = [NSMutableArray array];
    for(CLLocation *loc in locations)
    {
        MATraceLocation *tLoc = [[MATraceLocation alloc] init];
        tLoc.loc = loc.coordinate;
        
        tLoc.speed = loc.speed * 3.6; //m/s  转 km/h
        tLoc.time = [loc.timestamp timeIntervalSince1970] * 1000;
        tLoc.angle = loc.course;
        [mArr addObject:tLoc];
    }
    
    __weak typeof(self) weakSelf = self;
    __unused NSOperation *op = [self.traceManager queryProcessedTraceWith:mArr type:-1 processingCallback:nil  finishCallback:^(NSArray<MATracePoint *> *points, double distance) {
        
        NSLog(@"trace query done!");
        
        if (saving) {
            weakSelf.totalTraceLength = 0.0;
            [weakSelf.currentRecord updateTracedLocations:points];
            weakSelf.isSaving = NO;
            
            if ([weakSelf saveRoute])
            {
                [weakSelf.tipView showTip:@"recording save succeeded"];
            }
            else
            {
                [weakSelf.tipView showTip:@"recording save failed"];
            }
        }
        
        [weakSelf updateUserlocationTitleWithDistance:distance];
        [weakSelf addFullTrace:points];
        
    } failedCallback:^(int errorCode, NSString *errorDesc) {
        
        NSLog(@"query trace point failed :%@", errorDesc);
        if (saving) {
            weakSelf.isSaving = NO;
        }
    }];

}

- (void)addFullTrace:(NSArray<MATracePoint*> *)tracePoints
{
    MAPolyline *polyline = [self makePolylineWith:tracePoints];
    if(!polyline)
    {
        return;
    }
    
    [self.tracedPolylines addObject:polyline];
    [self.mapView addOverlay:polyline];
}

- (MAPolyline *)makePolylineWith:(NSArray<MATracePoint*> *)tracePoints
{
    if(tracePoints.count < 2)
    {
        return nil;
    }
    
    CLLocationCoordinate2D *pCoords = malloc(sizeof(CLLocationCoordinate2D) * tracePoints.count);
    if(!pCoords) {
        return nil;
    }
    
    for(int i = 0; i < tracePoints.count; ++i) {
        MATracePoint *p = [tracePoints objectAtIndex:i];
        CLLocationCoordinate2D *pCur = pCoords + i;
        pCur->latitude = p.latitude;
        pCur->longitude = p.longitude;
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:pCoords count:tracePoints.count];
    
    if(pCoords)
    {
        free(pCoords);
    }
    
    return polyline;
}

- (void)updateUserlocationTitleWithDistance:(double)distance
{
    self.totalTraceLength += distance;
    self.mapView.userLocation.title = [NSString stringWithFormat:@"距离：%.0f 米", self.totalTraceLength];
}

- (BOOL)saveRoute
{
    if (self.currentRecord == nil || self.currentRecord.numOfLocations < 2)
    {
        return NO;
    }
    
    NSString *name = self.currentRecord.title;
    NSString *path = [FileHelper filePathWithName:name];
    
    BOOL result = [NSKeyedArchiver archiveRootObject:self.currentRecord toFile:path];
    
    self.currentRecord = nil;
    
    return result;
}

#pragma mark - Initialization

- (void)initStatusView
{
    self.statusView = [[StatusView alloc] initWithFrame:CGRectMake(5, 35, 150, 150)];
    
    [self.view addSubview:self.statusView];
}

- (void)initTipView
{
    self.locationsArray = [[NSMutableArray alloc] init];
    
    self.tipView = [[TipView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height*0.95, self.view.bounds.size.width, self.view.bounds.size.height*0.05)];
    
    [self.view addSubview:self.tipView];
}

- (void)initMapView
{
    self.mapView = [[MAMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.zoomLevel = 16.0;
    self.mapView.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    self.mapView.showsIndoorMap = NO;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    
    self.traceManager = [[MATraceManager alloc] init];
}

- (void)initNavigationBar
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_play"] style:UIBarButtonItemStylePlain target:self action:@selector(actionRecordAndStop)];
    
    UIBarButtonItem *listButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_list"] style:UIBarButtonItemStylePlain target:self action:@selector(actionShowList)];
    
    NSArray *array = [[NSArray alloc] initWithObjects:listButton, nil];
    self.navigationItem.rightBarButtonItems = array;
    
    self.isRecording = NO;
    
    self.isSaving = NO;
}

- (void)initLocationButton
{
    self.imageLocated = [UIImage imageNamed:@"location_yes.png"];
    self.imageNotLocate = [UIImage imageNamed:@"location_no.png"];
    
    self.locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetHeight(self.view.bounds) - 90, 40, 40)];
    self.locationBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.locationBtn.backgroundColor = [UIColor whiteColor];
    self.locationBtn.layer.cornerRadius = 3;
    [self.locationBtn addTarget:self action:@selector(actionLocation) forControlEvents:UIControlEventTouchUpInside];
    [self.locationBtn setImage:self.imageNotLocate forState:UIControlStateNormal];
    
    [self.view addSubview:self.locationBtn];
}

#pragma mark - Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"My Route"];
    
    [self initNavigationBar];
    
    [self initMapView];
    
    [self initStatusView];
    
    [self initTipView];
    
    [self initLocationButton];
    
    self.tracedPolylines = [NSMutableArray array];
    self.tempTraceLocations = [NSMutableArray array];
    self.totalTraceLength = 0.0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.mapView.userTrackingMode = MAUserTrackingModeFollow;
}

@end
