//
//  ViewController.swift
//  iOS_3D_RecordPath-swift
//
//  Created by hanxiaoming on 17/1/22.
//  Copyright © 2017年 FENGSHENG. All rights reserved.
//

import UIKit

let kTempTraceLocationCount: Int = 10

class ViewController: UIViewController, MAMapViewDelegate {

    var mapView: MAMapView!
    var traceManager: MATraceManager!
    var isRecording: Bool = false
    var isSaving: Bool = false
    var locationButton: UIButton!
    var searchButton: UIButton!
    var imageLocated: UIImage!
    var imageNotLocate: UIImage!
    var tipView: TipView!
    var statusView: StatusView!
    var currentRecord: AMapRouteRecord?
    
    var polyline: MAPolyline?
    
    var tracedPolylines: Array<MAPolyline> = []
    var tempTraceLocations: Array<CLLocation> = []
    var totalTraceLength: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBar.isTranslucent = false
        
        initToolBar()
        initMapView()
        initTipView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = MAUserTrackingMode.follow
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tipView!.frame = CGRect(x: 0, y: view.bounds.height - 30, width: view.bounds.width, height: 30)
    }
    
    //MARK:- Initialization
    
    func initMapView() {
        
        AMapServices.shared().apiKey = APIKey
        mapView = MAMapView(frame: self.view.bounds)
        mapView.pausesLocationUpdatesAutomatically = false
        mapView.allowsBackgroundLocationUpdates = true
        mapView.distanceFilter = 10.0
        mapView.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        mapView.delegate = self
        self.view.addSubview(mapView)
        self.view.sendSubview(toBack: mapView)
        
        traceManager = MATraceManager()
    }
    
    func initToolBar() {
        
        let rightButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_list.png"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.actionHistory))
        
        navigationItem.rightBarButtonItem = rightButtonItem
        
        let leftButtonItem: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_play.png"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.actionRecordAndStop))
        
        navigationItem.leftBarButtonItem = leftButtonItem
        
        imageLocated = UIImage(named: "location_yes.png")
        imageNotLocate = UIImage(named: "location_no.png")
        
        locationButton = UIButton(frame: CGRect(x: 20, y: view.bounds.height - 80, width: 40, height: 40))
        
        locationButton!.autoresizingMask = [UIViewAutoresizing.flexibleRightMargin, UIViewAutoresizing.flexibleTopMargin]
        locationButton!.backgroundColor = UIColor.white
        locationButton!.layer.cornerRadius = 5
        locationButton!.layer.shadowColor = UIColor.black.cgColor
        locationButton!.layer.shadowOffset = CGSize(width: 5, height: 5)
        locationButton!.layer.shadowRadius = 5
        
        locationButton!.addTarget(self, action: #selector(self.actionLocation(sender:)), for: UIControlEvents.touchUpInside)
        
        locationButton!.setImage(imageNotLocate, for: UIControlState.normal)
        
        view.addSubview(locationButton!)
    }
    
    func initTipView() {
        tipView = TipView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 30))
        view.addSubview(tipView!)
        statusView = StatusView(frame: CGRect(x: 5, y: 35, width: 150, height: 150))
        
        statusView!.showStatusInfo(info: nil)
        
        view.addSubview(statusView!)
        
    }
    
    //MARK:- Actions
    
    func stopLocationIfNeeded() {
        if !isRecording {
            print("stop location")
            mapView!.setUserTrackingMode(MAUserTrackingMode.none, animated: false)
            mapView!.showsUserLocation = false
        }
    }
    
    func actionHistory() {
        print("actionHistory")
        
        let historyController = RecordViewController(nibName: nil, bundle: nil)
        historyController.title = "Records"
        
        navigationController!.pushViewController(historyController, animated: true)
    }
    
    func actionRecordAndStop() {
        print("actionRecord")
        
        isRecording = !isRecording
        
        if isRecording {
            
            showTip(tip: "Start recording...")
            navigationItem.leftBarButtonItem!.image = UIImage(named: "icon_stop.png")
            
            if currentRecord == nil {
                currentRecord = AMapRouteRecord()
            }
            
            addLocation(location: mapView!.userLocation.location)
        }
        else {
            navigationItem.leftBarButtonItem!.image = UIImage(named: "icon_play.png")
            
            addLocation(location: mapView!.userLocation.location)
            showTip(tip: "Recording stoppod")
            
            actionSave()
        }
        
    }
    
    func actionLocation(sender: UIButton) {
        print("actionLocation")
        
        if mapView!.userTrackingMode == MAUserTrackingMode.follow {
            
            mapView!.setUserTrackingMode(MAUserTrackingMode.none, animated: false)
            mapView!.showsUserLocation = false
        }
        else {
            mapView!.setUserTrackingMode(MAUserTrackingMode.follow, animated: true)
        }
    }
    
    //MARK:- Helpers
    
    func actionSave() {
        self.isRecording = false
        self.isSaving = true
        
        self.mapView.remove(self.polyline)
        self.polyline = nil
        
        // 全程请求trace
        self.mapView.removeOverlays(self.tracedPolylines)
        self.queryTrace(withLocations: self.currentRecord!.locations, withSaving: true)
    }
    
    func addLocation(location: CLLocation?) {
        if location == nil {
            return
        }
        currentRecord!.addLocation(location)
        showTip(tip: "locations: \(currentRecord!.locations.count)")
    }
    
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
    
    func addFullTrace(_ tracePoints: [MATracePoint]?) {
        let polyline: MAPolyline? = self.makePolyline(with: tracePoints)
        if polyline == nil {
            return
        }
        self.tracedPolylines.append(polyline!)
        self.mapView.add(polyline!)
    }
    
    func makePolyline(with tracePoints: [MATracePoint]?) -> MAPolyline? {
        if tracePoints == nil || tracePoints!.count < 2 {
            return nil
        }
        var pCoords = [CLLocationCoordinate2D]()

        for i in 0..<tracePoints!.count {
            pCoords.append(CLLocationCoordinate2D(latitude: tracePoints![i].latitude, longitude: tracePoints![i].longitude))
        }
        
        let polyline = MAPolyline(coordinates: &pCoords, count: UInt(pCoords.count))

        return polyline
    }
    
    func coordinatesFromLocationArray(locations: [CLLocation]?) -> [CLLocationCoordinate2D]? {
        if locations == nil || locations!.count == 0 {
            return nil
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        for location in locations! {
            coordinates.append(location.coordinate)
        }
        
        return coordinates
    }

    func updateUserlocationTitle(withDistance distance: Double) {
        self.totalTraceLength += distance
        self.mapView.userLocation.title = String(format: "距离：%.0f 米", self.totalTraceLength)
    }
    
    func saveRoute() {
        
        if currentRecord == nil || currentRecord!.locations.count < 2 {
            return
        }
        
        let name = currentRecord!.title()
        
        let path = FileHelper.filePath(withName: name)
        
        NSKeyedArchiver.archiveRootObject(currentRecord!, toFile: path!)
        
        currentRecord = nil
    }
    
    func showTip(tip: String?) {
        tipView!.showTip(tip: tip)
    }
    
    func hideTip() {
        tipView!.isHidden = true
    }
    
    //MARK:- MAMapViewDelegate
    
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
    
    func mapView(_ mapView: MAMapView, didChange mode: MAUserTrackingMode, animated: Bool) {
        if mode == MAUserTrackingMode.none {
            locationButton?.setImage(imageNotLocate, for: UIControlState.normal)
        }
        else {
            locationButton?.setImage(imageLocated, for: UIControlState.normal)
        }
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if self.polyline != nil && overlay.isEqual(self.polyline!) {
            let view = MAPolylineRenderer(polyline: overlay as! MAPolyline!)
            view?.lineWidth = 5.0
            view?.strokeColor = UIColor.red
            
            return view
        }
        if (overlay is MAPolyline) {
            let view = MAPolylineRenderer(polyline: overlay as! MAPolyline!)
            view?.lineWidth = 10.0
            view?.strokeColor = UIColor.darkGray.withAlphaComponent(0.8)
            return view
        }
        return nil
    }

}

