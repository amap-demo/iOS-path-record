//
//  StatusView.h
//  iOS_2D_RecordPath
//
//  Created by PC on 15/7/16.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;

@interface StatusView : UIView

- (void)showStatusWith:(CLLocation *)location;

@end
