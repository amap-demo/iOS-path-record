//
//  SystemInfoView.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/8/4.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "SystemInfoView.h"
#import "SystemInfo.h"

@interface  SystemInfoView()

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) double highestMemory;

@property (nonatomic, assign) float highestCpu;

@end

@implementation SystemInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        
        self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.textColor = [UIColor whiteColor];
        self.textView.font = [UIFont systemFontOfSize:14];
        self.textView.editable = NO;
        self.textView.selectable = NO;
        
        [self addSubview:self.textView];
        
        self.highestCpu = 0;
        self.highestMemory = 0;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateSystemInfo) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
    self.timer = nil;
}

- (void)updateSystemInfo
{
    double memory = [SystemInfo appMemoryOccpied];
    if (memory > self.highestMemory)
    {
        self.highestMemory = memory;
    }
    
    float cpu = [SystemInfo appCpuOccpied];
    if (cpu > self.highestCpu)
    {
        self.highestCpu = cpu;
    }
    
    NSMutableString *info = [[NSMutableString alloc] initWithString:@"System info:\nhighest cpu:\n"];
    [info appendString:[NSString stringWithFormat:@"%.2f%% cpu\n",self.highestCpu]];
    [info appendString:[NSString stringWithFormat:@"current cpu:\n%.2f%% cpu \n",cpu]];
    
    [info appendString:[NSString stringWithFormat:@"highest memory:\n%.2fM\n",self.highestMemory]];
    [info appendString:[NSString stringWithFormat:@"current memory:\n%.2fM",memory]];

    NSMutableAttributedString *showInfo = [[NSMutableAttributedString alloc] initWithString:info attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    NSRange pre = [info rangeOfString:@"current cpu:\n"];
    [showInfo addAttributes:@{NSForegroundColorAttributeName:[UIColor redColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:12]} range:NSMakeRange(pre.location+pre.length, [info rangeOfString:@"highest memory"].location-pre.location-pre.length)];
    
    pre = [info rangeOfString:@"current memory:\n"];
    [showInfo addAttributes:@{NSForegroundColorAttributeName:[UIColor redColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:12]}  range:NSMakeRange(pre.location+pre.length, info.length-pre.location-pre.length)];
    
    self.textView.attributedText = showInfo;
}

/* set a timer update view */
- (void)startUpdateSystemInfo
{
    [self.timer setFireDate:[NSDate distantPast]];
}

/* stop the timer */
- (void)stopUpdateSystemInfo
{
    [self.timer setFireDate:[NSDate distantFuture]];
}


@end
