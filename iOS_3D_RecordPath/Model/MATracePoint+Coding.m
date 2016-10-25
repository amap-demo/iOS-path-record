//
//  MATracePoint+Coding.m
//  iOS_3D_RecordPath
//
//  Created by xiaoming han on 16/10/24.
//  Copyright © 2016年 FENGSHENG. All rights reserved.
//

#import "MATracePoint+Coding.h"

@implementation MATracePoint (Coding)

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    
    self = [super init];
    if (self)
    {
        self.latitude = [aDecoder decodeDoubleForKey:@"latitude"];
        self.longitude = [aDecoder decodeDoubleForKey:@"longitude"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeDouble:self.latitude forKey:@"latitude"];
    [aCoder encodeDouble:self.longitude forKey:@"longitude"];
}

@end
