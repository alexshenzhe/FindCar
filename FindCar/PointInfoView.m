//
//  PointInfoView.m
//  FindCar
//
//  Created by 沈喆 on 17/6/21.
//  Copyright © 2017年 沈喆. All rights reserved.
//

#import "PointInfoView.h"

@interface PointInfoView ()

@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UILabel *GPSLabel;

@end

@implementation PointInfoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 添加四个边阴影
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 0); // 阴影偏移
        self.layer.shadowOpacity = 0.7; // 阴影透明度
        self.layer.shadowRadius = 5.0; // 阴影半径
        
        self.addressLabel = [[UILabel alloc] init];
        self.addressLabel.textAlignment = NSTextAlignmentLeft;
        self.addressLabel.font = [UIFont systemFontOfSize:15.0];
        [self addSubview:self.addressLabel];
        
        self.GPSLabel = [[UILabel alloc] init];
        self.GPSLabel.textAlignment = NSTextAlignmentLeft;
        self.GPSLabel.font = [UIFont systemFontOfSize:12.0];
        self.GPSLabel.textColor = [UIColor grayColor];
        [self addSubview:self.GPSLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    float viewW = [UIScreen mainScreen].bounds.size.width;
    float viewH = [UIScreen mainScreen].bounds.size.height / 5;
    float viewX = 0;
    float viewY = [UIScreen mainScreen].bounds.size.height - viewH;
    self.frame = CGRectMake(viewX, viewY, viewW, viewH);
    self.addressLabel.frame = CGRectMake(10, 30, self.bounds.size.width - 20, 20);
    self.GPSLabel.frame = CGRectMake(10, 50, self.bounds.size.width - 20, 20);
}

- (instancetype)initPointInfoViewWithAddress:(NSString *)address andGPS:(NSString *)GPSInfo {
    if (self = [super init]) {
        self.addressLabel.text = address;
        self.GPSLabel.text = GPSInfo;
    }
    return self;
}

@end
