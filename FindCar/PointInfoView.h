//
//  PointInfoView.h
//  FindCar
//
//  Created by 沈喆 on 17/6/21.
//  Copyright © 2017年 沈喆. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PointInfoView : UIView

- (instancetype)initPointInfoViewWithAddress:(NSString *)address andGPS:(NSString *)GPSInfo;

- (void)removeViewOutOfScreen;

- (void)setPointInfoViewAddress:(NSString *)address andGPS:(NSString *)GPSInfo;

@end
