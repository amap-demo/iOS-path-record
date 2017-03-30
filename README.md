本工程为基于高德地图iOS SDK进行封装，实现了定位轨迹记录并回放的功能
## 前述 ##
- [高德官网申请Key](http://lbs.amap.com/dev/#/).
- 阅读[开发指南](http://lbs.amap.com/api/ios-sdk/summary/).
- 工程基于iOS 3D地图SDK实现

## 功能描述 ##
基于3D地图SDK，可以记录定位点信息并保存，对保存的定位轨迹进行回放。保存的时候会进行轨迹纠偏操作，将定位点抓到道路上。

## 核心类/接口 ##
| 类    | 接口  | 说明   | 版本  |
| -----|:-----:|:-----:|:-----:|
| MovingAnnotationView	| - (void)addTrackingAnimationForPoints:(NSArray *)points duration:(CFTimeInterval)duration; | 继承自MAAnnotationView，实现了添加动画添加经纬度 | --- |
| MATraceManager	| - (NSOperation *)queryProcessedTraceWith:type:processingCallback:finishCallback:failedCallback: | 获取纠偏后的经纬度点集 | v4.3.0 |


## 核心难点 ##

`Objective-C`
```
/* 定位回调 */
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

/* 对记录的轨迹进行纠偏. */
- (void)queryTraceWithLocations:(NSArray<CLLocation *> *)locations withSaving:(BOOL)saving
{
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
```

`Swift`
```
func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
    if !updatingLocation {
        return
    }
    
    let location: CLLocation? = userLocation.location
    
    if location == nil || !isRecording {
        return
    }
    
    // filter the result
    if userLocation.location.horizontalAccuracy < 100.0 {
        
        let lastDis = userLocation.location.distance(from: self.currentRecord!.endLocation())
        
        if lastDis < 0.0 || lastDis > 10 {
            addLocation(location: userLocation.location)
            
            if self.polyline == nil {
                self.polyline = MAPolyline.init(coordinates: nil, count: 0)
                self.mapView.add(self.polyline!)
            }
            
            var coordinates = coordinatesFromLocationArray(locations: self.currentRecord!.locations)
            
            if coordinates != nil {
                self.polyline!.setPolylineWithCoordinates(&coordinates!, count: coordinates!.count)
            }
            
            self.mapView.setCenter(userLocation.location.coordinate, animated: true)
            // trace
            self.tempTraceLocations.append(userLocation.location)
            if self.tempTraceLocations.count >= kTempTraceLocationCount {
                self.queryTrace(withLocations: self.tempTraceLocations, withSaving: false)
                self.tempTraceLocations.removeAll()
                // 把最后一个再add一遍，否则会有缝隙
                self.tempTraceLocations.append(userLocation.location)
            }

        }
    }
    
    var speed = location!.speed
    if speed < 0.0 {
        speed = 0.0
    }
    
    let infoArray: [(String, String)] = [
        ("coordinate", NSString(format: "<%.4f, %.4f>", location!.coordinate.latitude, location!.coordinate.longitude) as String),
        ("speed", NSString(format: "%.2fm/s(%.2fkm/h)", speed, speed * 3.6) as String),
        ("accuracy", "\(location!.horizontalAccuracy)m"),
        ("altitude", NSString(format: "%.2fm", location!.altitude) as String)]
    
    statusView!.showStatusInfo(info: infoArray)
}

* 对记录的轨迹进行纠偏. */
func queryTrace(withLocations locations: [CLLocation], withSaving saving: Bool) {
    var mArr = [MATraceLocation]()
    for loc: CLLocation in locations {
        let tLoc = MATraceLocation()
        tLoc.loc = loc.coordinate
        tLoc.speed = loc.speed * 3.6
        //m/s  转 km/h
        tLoc.time = loc.timestamp.timeIntervalSince1970 * 1000
        tLoc.angle = loc.course
        mArr.append(tLoc)
    }

    weak var weakSelf = self
    
    _ = traceManager.queryProcessedTrace(with: mArr, type: AMapCoordinateType(rawValue: UInt.max)!, processingCallback: { (index:Int32, arr:[MATracePoint]?) in
        
    }, finishCallback: { (arr:[MATracePoint]?, distance:Double) in
        if saving {
            weakSelf?.totalTraceLength = 0.0
            weakSelf?.currentRecord?.updateTracedLocations(arr)
            weakSelf?.saveRoute()
            weakSelf?.isSaving = false
            weakSelf?.showTip(tip: "recording save done")
        }
        weakSelf?.updateUserlocationTitle(withDistance: distance)
        weakSelf?.addFullTrace(arr)
        
    }, failedCallback: { (errCode:Int32, errDesc:String?) in
        print(errDesc ?? "error")
        weakSelf?.isSaving = false
    })
        
}

```