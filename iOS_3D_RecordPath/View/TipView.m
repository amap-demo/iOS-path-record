//
//  TipView.m
//  iOS_2D_RecordPath
//
//  Created by PC on 15/7/16.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "TipView.h"

@interface TipView()

@property(nonatomic, strong) UILabel *label;

@end


@implementation TipView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.label = [[UILabel alloc] initWithFrame:self.bounds];
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.label.textColor = [UIColor whiteColor];
        self.label.text = @"tip";
        self.label.font = [UIFont systemFontOfSize:20];
                                
        [self addSubview:self.label];
    }
    return self;
}

- (void)showTip:(NSString *)tip
{
    self.label.text = tip;
}
@end
