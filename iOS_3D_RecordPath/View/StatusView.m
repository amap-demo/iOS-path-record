//
//  StatusView.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/7/16.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "StatusView.h"


#define controlHeight 20

@interface StatusView()

@property (nonatomic, strong) UIButton *control;

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, assign) BOOL isOpen;

@property (nonatomic, assign) CGRect originFrame;

@end

@implementation StatusView

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.isOpen = YES;
        self.originFrame = self.frame;
        
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        
        self.control = [UIButton buttonWithType:UIButtonTypeCustom];
        self.control.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), controlHeight);
        self.control.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6];
        [self.control setTitle:@"opened" forState:UIControlStateNormal];
        [self.control addTarget:self action:@selector(actionSwitch) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:self.control];
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, controlHeight, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-controlHeight)];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.font = [UIFont systemFontOfSize:12];
        self.textView.editable = NO;
        self.textView.selectable = NO;
        
        [self addSubview:self.textView];
        
    }
    return self;
}

- (void)actionSwitch
{
    _isOpen = ! _isOpen;
    
    if (_isOpen)
    {
        [_control setTitle:@"opened" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = _originFrame;
            self.textView.frame = CGRectMake(0, controlHeight, self.frame.size.width, self.frame.size.height-controlHeight);
        }];
    }
    else
    {
        [_control setTitle:@"closed" forState:UIControlStateNormal];
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = CGRectMake(self.originFrame.origin.x, self.originFrame.origin.y, self.originFrame.size.width, controlHeight);
            self.textView.frame = CGRectMake(0, 0, 0, 0);
        }];
    }
}

- (void)showStatusWith:(CLLocation *)location
{
    NSMutableString *info = [[NSMutableString alloc] init];
    [info appendString:@"coordinate:\n"];
    [info appendString:[NSString stringWithFormat:@"%.4f, %.4f\n", location.coordinate.latitude,location.coordinate.longitude]];
    
    [info appendString:@"speed:\n"];
    
    double speed = location.speed > 0 ? location.speed : 0;
    [info appendString:[NSString stringWithFormat:@"<%.2fm/s(%.2fkm/h)>\n", speed, speed * 3.6]];
    
    [info appendString:@"accuracy:\n"];
    [info appendString:[NSString stringWithFormat:@"%.2fm\n", location.horizontalAccuracy]];
    
    [info appendString:@"altitude:\n"];
    [info appendString:[NSString stringWithFormat:@"%.2fm", location.altitude]];
    
    _textView.text = info;
}

@end
