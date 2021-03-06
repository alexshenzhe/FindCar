//
//  MapViewController.m
//  FindCar
//
//  Created by 沈喆 on 17/6/10.
//  Copyright © 2017年 沈喆. All rights reserved.
//

#import "MapViewController.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "MBProgressHUD.h"
#import "PointInfoView.h"

@interface MapViewController () <AMapLocationManagerDelegate, UIGestureRecognizerDelegate, MAMapViewDelegate, AMapSearchDelegate>

@property (nonatomic, strong) MAMapView *mapView; // 地图view
@property (nonatomic, strong) AMapLocationManager *locationManager; // 定位
@property (nonatomic, strong) MAPointAnnotation *pointAnnotation; // 大头针
@property (nonatomic, strong) NSMutableArray *userLocationArray; // 存储用户定位信息
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) AMapRoute *route; // 路径规划信息
@property (nonatomic, strong) NSMutableArray *polylineArray; // 规划路径对象
@property (nonatomic, copy) NSString *addressInfo; // 地址
@property (nonatomic, strong) UIButton *locationButton; // 定位按钮
@property (nonatomic, strong) UIButton *startPlanningButton; // 路径规划按钮
@property (nonatomic, strong) PointInfoView *pointInfoView; // 点位信息view
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer; // 长按手势
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer; // 单击手势

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self showMapToView:self.view];
    [self setNavigationBarDefault];
    // 添加长按手势
    [self.mapView addGestureRecognizer:[self addLongPressGestureRecognizerToView]];
    // 添加点击手势
    [self.mapView addGestureRecognizer:[self addTapGestureRecognizerToView]];
    
    [self createSubviewIfMoveUp:NO];
    // 显示路况
    self.mapView.showTraffic = YES;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * 显示文字提示信息弹出框
 */
- (void)showMessageHUDWithString:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        // 设置显示模式
        hud.mode = MBProgressHUDModeText;
        hud.label.text = string;
        hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
        // 持续时间
        [hud hideAnimated:YES afterDelay:2.f];
    });
}

# pragma mark - 子控件

/**
 * 定位按钮
 */
- (void)createSubviewIfMoveUp:(BOOL)ifMoveUp {
    if (!self.locationButton) {
        self.locationButton = [[UIButton alloc] init];
    }
    
    float buttonW = 30;
    float buttonH = buttonW;
    float buttonX = 10;
    float buttonY = 0;
    if (!ifMoveUp) {
        buttonY = [UIScreen mainScreen].bounds.size.height - (buttonH + 30);
    } else {
        buttonY = [UIScreen mainScreen].bounds.size.height - (buttonH + 30 + [UIScreen mainScreen].bounds.size.height / 5);
    }
    self.locationButton.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
    
    [self.locationButton setTitle:@"1" forState:UIControlStateNormal];
    self.locationButton.backgroundColor = [UIColor grayColor];
    [self.locationButton addTarget:self action:@selector(userLocationCenter) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.locationButton];
    
}

/**
 * 定位方法
 */
- (void)userLocationCenter {
    self.locationManager = [[AMapLocationManager alloc] init];
    
    // 带逆地理信息的一次定位（返回坐标和地址信息）
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    // 定位超时时间，最低2s，此处设置为2s
    self.locationManager.locationTimeout = 2;
    // 逆地理请求超时时间，最低2s，此处设置为2s
    self.locationManager.reGeocodeTimeout = 2;
    
    // 带逆地理（返回坐标和地址信息）。将下面代码中的 YES 改成 NO ，则不会返回地址信息。
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        if (error) {
            if (error.code == AMapLocationErrorLocateFailed) {
                return;
            }
        }
        // 中心点移到当前定位位置
        [self.mapView setCenterCoordinate:location.coordinate animated:YES];
        NSLog(@"location:%@", location);
        if (regeocode) {
            NSLog(@"reGeocode:%@", regeocode);
        }
    }];
}

# pragma mark - 地图
/**
 * 显示地图在view上
 */
- (void)showMapToView:(UIView *)view {
    [AMapServices sharedServices].enableHTTPS = YES;
    // 创建地图
    MAMapView *mapView = [[MAMapView alloc] initWithFrame:view.bounds];
    // 默认地图缩放层级
    [mapView setZoomLevel:17.0 animated:YES];
    // 指南针位置显示在右上角
    mapView.compassOrigin = CGPointMake([UIScreen mainScreen].bounds.size.width - (mapView.compassSize.width + 10), 74);
    // 显示用户位置
    mapView.showsUserLocation = YES;
    // 追踪用户的location更新
    mapView.userTrackingMode = MAUserTrackingModeFollow;
    // 显示室内地图
    mapView.showsIndoorMap = YES;
    // 将地图显示到view上
    [view addSubview:mapView];
    self.mapView = mapView;
}

- (void)cleanMapView {
    // 清空已有大头针
    [self.mapView removeAnnotation:self.pointAnnotation];
    
    // 清理路径规划
    [self.mapView removeOverlays:self.polylineArray];
    [self.polylineArray removeAllObjects];
    
}

# pragma mark - NavigationBar

- (void)setNavigationBarDefault {
    UIBarButtonItem *locationButton = [[UIBarButtonItem alloc] initWithTitle:@"我的车" style:UIBarButtonItemStylePlain target:self action:@selector(findMyCar)];
    self.navigationItem.leftBarButtonItem = locationButton;
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveUserLocation)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    self.title = @"首页";
}

/**
 * 找车
 */
- (void)findMyCar {
    self.navigationItem.leftBarButtonItem.enabled = NO;
    if (self.userLocationArray.count < 1) {
        [self showMessageHUDWithString:@"没有保存车辆位置"];
        return;
    }
    // 清空已有大头针 显示保存的大头针
    [self showCurrentPoint];
    
    // 显示下方详细页
    NSString *GPSInfo = [NSString stringWithFormat:@"%f,%f",self.pointAnnotation.coordinate.longitude, self.pointAnnotation.coordinate.latitude];
    [self showPointInfoViewWithGPS:GPSInfo andAddress:[self.userLocationArray lastObject][@"address"] ifShowGoButton:YES];
}

/**
 * 显示当前保存的位置
 */
- (void)showCurrentPoint {
    [self cleanMapView];
    NSDictionary *location = [self.userLocationArray lastObject];
    float latitude = [location[@"latitude"] floatValue];
    float longitude = [location[@"longitude"] floatValue];
    CLLocationCoordinate2D coordinate2d =  CLLocationCoordinate2DMake(latitude, longitude);
    self.pointAnnotation = [self addPointAnnotationTo:coordinate2d];
    [self.mapView addAnnotation:self.pointAnnotation];
}

/**
 * 保存
 */
- (void)saveUserLocation {
    NSString *longitude = [[NSString alloc] initWithFormat:@"%f",self.pointAnnotation.coordinate.longitude];
    NSString *latitude = [[NSString alloc] initWithFormat:@"%f",self.pointAnnotation.coordinate.latitude];
    
    NSDictionary *location = [NSDictionary dictionaryWithObjectsAndKeys:longitude, @"longitude", latitude, @"latitude", self.addressInfo, @"address", nil];
    [self.userLocationArray removeAllObjects];
    [self.userLocationArray addObject:location];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/userLocation.plist"];
    NSLog(@"%@", path);
    BOOL success = [self.userLocationArray writeToFile:path atomically:YES];
    if (success) {
        [self showMessageHUDWithString:@"保存成功！"];
    }
}

# pragma mark - 路线规划

- (void)searchRoutePlanningWalk {
    NSLog(@"searchRoutePlanningWalk");
    AMapWalkingRouteSearchRequest *navi = [[AMapWalkingRouteSearchRequest alloc] init];
    
    // 出发点
    navi.origin = [AMapGeoPoint locationWithLatitude:self.mapView.userLocation.location.coordinate.latitude
                                           longitude:self.mapView.userLocation.location.coordinate.longitude];
    // 目的地
    navi.destination = [AMapGeoPoint locationWithLatitude:[self.userLocationArray.lastObject[@"latitude"] floatValue]
                                                longitude:[self.userLocationArray.lastObject[@"longitude"] floatValue]];
    [self.search AMapWalkingRouteSearch:navi];
}

/**
 * 路径解析
 */
- (void)routeAnalysis {
    // 分多个step完成一次路径规划
    for (int step = 0; step < self.route.paths[0].steps.count; step ++) {
        NSString *pathsString = self.route.paths[0].steps[step].polyline;
        NSArray *pathsArray = [pathsString componentsSeparatedByString:@";"];
        CLLocationCoordinate2D commonPolylineCoords[pathsArray.count];
        
        for (int i =0; i < pathsArray.count; i ++) {
            NSString *onePathString = [NSString string];
            onePathString = pathsArray[i];
            NSArray *onePathArray = [NSArray array];
            onePathArray = [onePathString componentsSeparatedByString:@","];
            // 构造路径数据对象
            commonPolylineCoords[i].longitude = [onePathArray[0] floatValue];
            commonPolylineCoords[i].latitude = [onePathArray[1] floatValue];
        }
        // 构造路径
        MAPolyline *commonPolyline = [MAPolyline polylineWithCoordinates:commonPolylineCoords count:pathsArray.count];
        [self.polylineArray addObject:commonPolyline];
    }
    // 在地图上显示路径
    [self.mapView addOverlays:self.polylineArray];
}

# pragma mark - AMapSearchDelegate
/**
 * 路径规划回调函数
 */
- (void)onRouteSearchDone:(AMapRouteSearchBaseRequest *)request response:(AMapRouteSearchResponse *)response {
    NSLog(@"onRouteSearchDone");
    if (response.route == nil) {
        return;
    }
    self.route = response.route;
    NSLog(@"path:%@", response.route.paths[0].steps[0].polyline);
    [self routeAnalysis];
}

/**
 * 逆地理编码回调函数
 */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    NSLog(@"onReGeocodeSearchDone");
    if (response.regeocode) {
        NSString *address = [NSString string];
        address = response.regeocode.formattedAddress;
        self.addressInfo = address;
        NSLog(@"address:%@", address);
        // 详细信息view
        NSString *GPSInfo = [[NSString alloc] initWithFormat:@"%f,%f",self.pointAnnotation.coordinate.longitude, self.pointAnnotation.coordinate.latitude];
        [self showPointInfoViewWithGPS:GPSInfo andAddress:self.addressInfo ifShowGoButton:NO];
    }
}

# pragma mark - 点位详细信息view

/**
 * 创建点位详细信息view
 */
- (void)showPointInfoViewWithGPS:(NSString *)GPSInfo andAddress:(NSString *)address ifShowGoButton:(BOOL)showGoButton {
    if (!self.pointInfoView) {
        // 调整定位按钮
        [self createSubviewIfMoveUp:YES];
        
        self.pointInfoView = [[PointInfoView alloc] initPointInfoViewWithAddress:address andGPS:GPSInfo];
    } else {
        [self.pointInfoView setPointInfoViewAddress:address andGPS:GPSInfo];
    }
    [self.navigationController.view addSubview:self.pointInfoView];
    // 是否显示导航按钮
    if (showGoButton) {
        float viewW = [UIScreen mainScreen].bounds.size.width;
        float viewY = [UIScreen mainScreen].bounds.size.height * 4 / 5;
        if (!self.startPlanningButton) {
            self.startPlanningButton = [[UIButton alloc] init];
        }
        self.startPlanningButton.frame = CGRectMake(viewW - 80, viewY - 30, 60, 60);
        [self.startPlanningButton addTarget:self action:@selector(searchRoutePlanningWalk) forControlEvents:UIControlEventTouchUpInside];
        [self.startPlanningButton setTitle:@"路线" forState:UIControlStateNormal];
        self.startPlanningButton.backgroundColor = [UIColor blueColor];
        [self.navigationController.view addSubview:self.startPlanningButton];
    }
    
}

/**
 * 清除详细信息view及路径规划按钮
 */
- (void)cleanPointInfoView {
    [UIView animateWithDuration:1.0 animations:^{
        // 移动导航按钮及详细信息view
        [self.pointInfoView removeViewOutOfScreen];
        self.startPlanningButton.center = CGPointMake([UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.height + 30);
        // 移动定位按钮
        [self createSubviewIfMoveUp:NO];
    } completion:^(BOOL finished) {
        [self.pointInfoView removeFromSuperview];
        self.pointInfoView = nil;
        [self.startPlanningButton removeFromSuperview];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }];
}

# pragma mark - 手势识别

/**
 * 支持多手势
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/**
 * 长按手势
 */
- (UILongPressGestureRecognizer *)addLongPressGestureRecognizerToView {
    // 长按手势
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    longPressGestureRecognizer.delegate = self;
    longPressGestureRecognizer.minimumPressDuration = 1.0;
    longPressGestureRecognizer.allowableMovement = 50.0;
    self.longPressGestureRecognizer = longPressGestureRecognizer;
    return self.longPressGestureRecognizer;
}

/**
 * 长按调用方法
 */
- (void)longPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    // 坐标转换
    CGPoint longPressPoint = [sender locationInView:self.mapView];
    CLLocationCoordinate2D coordinate2d = [self.mapView convertPoint:longPressPoint toCoordinateFromView:self.mapView];
    //添加大头针
    MAPointAnnotation *pointAnnotation = [self addPointAnnotationTo:coordinate2d];
    [self.mapView addAnnotation:pointAnnotation];
    self.pointAnnotation = pointAnnotation;
    self.mapView.delegate = self;
    // 获取地址信息
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:self.pointAnnotation.coordinate.latitude longitude:self.pointAnnotation.coordinate.longitude];
    regeo.requireExtension = YES;
    [self.search AMapReGoecodeSearch:regeo];
}

/**
 * 单击手势
 */
- (UITapGestureRecognizer *)addTapGestureRecognizerToView {
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    // 排除与长按手势的干扰
    [tapGestureRecognizer requireGestureRecognizerToFail:self.longPressGestureRecognizer];
    tapGestureRecognizer.delegate = self;
    return tapGestureRecognizer;
}

/**
 * 单击调用方法
 */
- (void)tap:(UITapGestureRecognizer *)sender {
    // 移除屏幕上的大头针及view
    [self cleanPointInfoView];
    [self cleanMapView];
}

# pragma mark - 添加大头针

- (MAPointAnnotation *)addPointAnnotationTo:(CLLocationCoordinate2D)coordinate2d {
    // 清空已有大头针
    [self cleanMapView];
    MAPointAnnotation *pointAnnotation = [[MAPointAnnotation alloc] init];
    pointAnnotation.coordinate = coordinate2d;
    pointAnnotation.title = @"我在这里";
    pointAnnotation.subtitle = @"使用这个位置";
    self.mapView.delegate = self;
    return pointAnnotation;
}

# pragma mark - MAMapViewDelegate

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    NSLog(@"viewForAnnotation");
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        annotationView.canShowCallout = YES;      //设置气泡可以弹出
        annotationView.animatesDrop = YES;        //设置标注动画显示
        annotationView.draggable = YES;           //设置标注可以拖动
        return annotationView;
    }
    return nil;
}

/**
 * 设置路径规划线段颜色等
 */
- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay {
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineRenderer *polylineRenderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.lineWidth    = 8.f;
        polylineRenderer.strokeColor  = [UIColor blueColor];
        polylineRenderer.lineJoinType = kMALineJoinRound;
        polylineRenderer.lineCapType  = kMALineCapRound;
        return polylineRenderer;
    }
    return nil;
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    NSLog(@"select-------");
}

# pragma mark - 懒加载

- (NSMutableArray *)userLocationArray {
    if (_userLocationArray == nil) {
        NSLog(@"userLocationArray == nil");
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/userLocation.plist"];
        NSArray *dicArray = [NSArray arrayWithContentsOfFile:path];
        NSLog(@"dicArray--%@", dicArray);
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *dic in dicArray) {
            [array addObject:dic];
        }
        _userLocationArray = array;
    }
    return _userLocationArray;
}

- (AMapSearchAPI *)search {
    if (_search == nil) {
        _search = [[AMapSearchAPI alloc] init];
        _search.delegate = self;
    }
    return _search;
}

- (AMapRoute *)route {
    if (_route == nil) {
        _route = [[AMapRoute alloc] init];
    }
    return _route;
}

- (NSMutableArray *)polylineArray {
    if (_polylineArray == nil) {
        _polylineArray = [[NSMutableArray alloc] init];
    }
    return _polylineArray;
}

@end
