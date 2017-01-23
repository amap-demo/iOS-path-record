//
//  Record.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/3.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "AMapRouteRecord.h"

@interface AMapRouteRecord()<NSCoding>

@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;

@property (nonatomic, strong) NSMutableArray<CLLocation *> *locationsArray;
@property (nonatomic, strong) NSMutableArray<MATracePoint *> *tracedLocationsArray;

@property (nonatomic, assign) CLLocationCoordinate2D *coords;

@end


@implementation AMapRouteRecord

#pragma mark - interface

- (void)updateTracedLocations:(NSArray<MATracePoint *> *)tracedLocations
{
    [self.tracedLocationsArray addObjectsFromArray:tracedLocations];
}

- (void)addLocation:(CLLocation *)location
{
    if (location == nil)
    {
        return;
    }
    _endTime = [NSDate date];
    [self.locationsArray addObject:location];
}

- (CLLocation *)startLocation
{
    return [self.locationsArray firstObject];
}

- (CLLocation *)endLocation
{
    return [self.locationsArray lastObject];
}

- (CLLocationCoordinate2D *)coordinates
{
    if (self.coords != NULL)
    {
        free(self.coords);
        self.coords = NULL;
    }
    
    self.coords = (CLLocationCoordinate2D *)malloc(self.locationsArray.count * sizeof(CLLocationCoordinate2D));
    
    for (int i = 0; i < self.locationsArray.count; i++)
    {
        CLLocation *location = self.locationsArray[i];
        self.coords[i] = location.coordinate;
    }
    
    return self.coords;
}

- (NSArray<CLLocation *> *)locations
{
    return [self.locationsArray copy];
}

- (NSArray<MATracePoint *> *)tracedLocations
{
    return [self.tracedLocationsArray copy];
}

- (NSString *)title
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    
    return [formatter stringFromDate:self.startTime];
}

- (NSString *)subTitle
{
    return [NSString stringWithFormat:@"point:%d, distance: %.2fm, duration: %.2fs", @(self.locationsArray.count).intValue, [self totalDistance], [self totalDuration]];
}

- (CLLocationDistance)totalDistance
{
    CLLocationDistance distance = 0;
    
    if (self.locationsArray.count > 1)
    {
        CLLocation *currentLocation = [self.locationsArray firstObject];
        for (CLLocation *location in self.locationsArray)
        {
            distance += [location distanceFromLocation:currentLocation];
            currentLocation = location;
        }
    }
    
    return distance;
}

- (NSTimeInterval)totalDuration
{
    return [self.endTime timeIntervalSinceDate:self.startTime];
}

- (NSInteger)numOfLocations;
{
    return self.locationsArray.count;
}

#pragma mark - NSCoding Protocol

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        self.startTime = [aDecoder decodeObjectForKey:@"startTime"];
        self.endTime = [aDecoder decodeObjectForKey:@"endTime"];
        self.locationsArray = [aDecoder decodeObjectForKey:@"locations"];
        self.tracedLocationsArray = [aDecoder decodeObjectForKey:@"tracedLocationsArray"];
        
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.startTime forKey:@"startTime"];
    [aCoder encodeObject:self.endTime forKey:@"endTime"];
    [aCoder encodeObject:self.locationsArray forKey:@"locations"];
    [aCoder encodeObject:self.tracedLocationsArray forKey:@"tracedLocationsArray"];
}

#pragma mark - Life Cycle

- (id)init
{
    self = [super init];
    if (self)
    {
        _startTime = [NSDate date];
        _endTime = _startTime;
        _locationsArray = [[NSMutableArray alloc] init];
        _tracedLocationsArray = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}

@end
