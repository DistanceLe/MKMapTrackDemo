//
//  LJMapTrackView.m
//  MKMapDemo
//
//  Created by LiJie on 2017/2/9.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import "LJMapTrackView.h"
#import "GradientPolylineOverlay.h"
#import "GradientPolylineRenderer.h"

@interface LJMapTrackView ()<MKMapViewDelegate, CLLocationManagerDelegate>

@property(nonatomic, strong)MKMapView*          mapView;
@property(nonatomic, strong)MKPolygon*          backMaskPolygon;

@property(nonatomic, strong)CLLocationManager*  locationManager;

@property(nonatomic, strong)NSMutableArray* locations;
@property(nonatomic, strong)NSMutableArray<CLLocation *>* mapLocations;
@property(nonatomic, strong)CLLocation*     currentLocation;
@property(nonatomic, assign)CGFloat         currentSpan; //当前的跨度

@property(nonatomic, assign)BOOL isRun;
@property(nonatomic, assign)BOOL isFirst;

@property(nonatomic, strong)MapLocationBlock tempBlock;

@end

@implementation LJMapTrackView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
    }
    return self;
}

-(void)dealloc{
    NSLog(@"View dealloc.......");
    [self removeTrack];
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
}

-(UIColor *)fillColor{
    if (!_fillColor) {
        _fillColor = [UIColor greenColor];
    }
    return _fillColor;
}

-(UIColor *)strokeColor{
    if (!_strokeColor) {
        _strokeColor = [UIColor redColor];
    }
    return _strokeColor;
}

-(CGFloat)lineWidth{
    if (_lineWidth<0.01) {
        _lineWidth = 5.0;
    }
    return _lineWidth;
}

-(void)initData{
    
    self.isFirst = YES;
    self.isWatchMode = YES;
    self.currentSpan = 0.001;
    self.locations = [NSMutableArray new];
    self.mapLocations = [NSMutableArray new];
    
    self.mapView = [[MKMapView alloc]initWithFrame:self.bounds];
    self.mapView.showsUserLocation = YES;
    self.mapView.showsScale = YES;
    self.mapView.showsCompass = YES;
    self.mapView.delegate = self;
    
    [self addSubview: self.mapView];
    
    
    self.locationManager = [[CLLocationManager alloc]init];
    if (![CLLocationManager locationServicesEnabled]){
        //NSLog(@"定位服务未打开，请打开");
        return;
    }
    
    //如果没有授权则请求用户授权 ,可以设置为： 只在使用时 和 一直
    if ([CLLocationManager authorizationStatus]!=kCLAuthorizationStatusAuthorizedAlways){
        [self.locationManager requestAlwaysAuthorization];
    }
    
    self.locationManager.allowsBackgroundLocationUpdates = YES;
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 5.0;//5米定位一次
}

-(void)callBackHandler:(MapLocationBlock)handler{
    self.tempBlock = handler;
}

-(void)addTrackPoint:(NSArray<CLLocation *> *)coordinates{
    if (coordinates.count >= 1) {
        
        //取出 已有路径的 最后一个点，和要增加的点 合起来。
        NSMutableArray<CLLocation *>* tempArray = [NSMutableArray new];
        if (self.mapLocations.count>0) {
            [tempArray addObject:self.mapLocations.lastObject];
        }
        [self.mapLocations addObjectsFromArray:coordinates];
        [tempArray addObjectsFromArray:coordinates];
        if (tempArray.count <= 1) {
            return;
        }
        
        //替换方案:
        tempArray = [NSMutableArray arrayWithArray:self.mapLocations];
        
        //遍历所有点
        CLLocationCoordinate2D  pointCoords[tempArray.count];
        float velocitys[tempArray.count];
        
        for (NSInteger i = 0; i<tempArray.count; i++) {
            pointCoords[i] = tempArray[i].coordinate;
            velocitys[i] = tempArray[i].speed;
//            velocitys[i] = arc4random()%100/10.0;
        }
        
        GradientPolylineOverlay* line = [[GradientPolylineOverlay alloc] initWithPoints:pointCoords velocity:velocitys count:tempArray.count];
//        MKPolyline* line = [MKPolyline polylineWithCoordinates:pointCoords count:tempArray.count];
//        line.subtitle = @"location";
        
        //替换方案:
        if (self.mapView.overlays.count>0) {
            for (id<MKOverlay> ovrelay in self.mapView.overlays) {
                if ([ovrelay isKindOfClass:[GradientPolylineOverlay class]]) {
                    [self.mapView removeOverlay:ovrelay];
                }
            }
        }
        
        [self.mapView addOverlay:line];
    }
    if (self.mapLocations.count > 2) {
        CLLocationCoordinate2D* startEnd = malloc(sizeof(CLLocationCoordinate2D)*2);
        startEnd[0] = self.mapLocations.firstObject.coordinate;
        startEnd[1] = self.mapLocations.lastObject.coordinate;
        [self showStartAndEndAnnotationLocation:startEnd];
    }
    
}

-(void)addTrackMapPoint:(NSArray<CLLocation *> *)coordinates{
    if (coordinates.count >= 1) {
        //取出 已有路径的 最后一个点，和要增加的点 合起来。
        NSMutableArray<CLLocation *>* tempArray = [NSMutableArray new];
        if (self.mapLocations.count>0) {
            [tempArray addObject:self.mapLocations.lastObject];
        }
        [self.mapLocations addObjectsFromArray:coordinates];
        [tempArray addObjectsFromArray:coordinates];
        if (tempArray.count <= 1) {
            return;
        }
        
        //遍历所有点
        CLLocationCoordinate2D  pointCoords[tempArray.count];
        float velocitys[tempArray.count];
        
        for (NSInteger i = 0; i<tempArray.count; i++) {
            pointCoords[i] = tempArray[i].coordinate;
            velocitys[i] = tempArray[i].speed;
        }

        GradientPolylineOverlay* line = [[GradientPolylineOverlay alloc] initWithPoints:pointCoords velocity:velocitys count:tempArray.count];
//        MKPolyline* line = [MKPolyline polylineWithCoordinates:pointCoords count:tempArray.count];
//        line.subtitle = @"map";
        [self.mapView addOverlay:line];
    }
    
    if (self.mapLocations.count > 2) {
        CLLocationCoordinate2D* startEnd = malloc(sizeof(CLLocationCoordinate2D)*2);
        startEnd[0] = self.mapLocations.firstObject.coordinate;
        startEnd[1] = self.mapLocations.lastObject.coordinate;
        [self showStartAndEndAnnotationLocation:startEnd];
    }
}

/**  快速 切换一遍 地图的类型， 以便释放掉内存 */
- (void)applyMapViewMemoryHotFix{
    
    switch (self.mapView.mapType) {
        case MKMapTypeHybrid:{
            self.mapView.mapType = MKMapTypeStandard;
            break;
        }
        case MKMapTypeStandard:{
            self.mapView.mapType = MKMapTypeHybrid;
            break;
        }
        default:
            break;
    }
    self.mapView.mapType = MKMapTypeStandard;
}

-(void)setMapCurrentLocation:(CLLocationCoordinate2D)coordinate{
    self.currentLocation = [[CLLocation alloc]initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    //经纬度的 跨度
    MKCoordinateSpan span = MKCoordinateSpanMake(0.003, 0.003);
    
    //显示的区域，由一个中心点 和 跨度决定
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [self.mapView setRegion:region animated:YES];
}

-(void)startRun{
    if (!self.isWatchMode && !self.isRun) {
        self.isRun = YES;
        [self.locationManager startUpdatingLocation];
    }
}

-(void)stopRun{
    if (!self.isWatchMode && self.isRun) {
        self.isRun = NO;
        [self.locationManager stopUpdatingLocation];
    }
}

-(void)removeTrack{
    if (self.mapView.overlays.count>0) {
        [self.mapView removeOverlays:self.mapView.overlays];
        [self.locations removeAllObjects];
        [self.mapLocations removeAllObjects];
    }
}

/**  显示区域改变的时候 刷新背景蒙版 */
-(void)setBackMask{
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    CLLocationCoordinate2D leftTop =[self.mapView convertPoint:CGPointMake(0, 0) toCoordinateFromView:self];
    CLLocationCoordinate2D rightTop =[self.mapView convertPoint:CGPointMake(width, 0) toCoordinateFromView:self];
    CLLocationCoordinate2D leftBottom =[self.mapView convertPoint:CGPointMake(0, height) toCoordinateFromView:self];
    CLLocationCoordinate2D rightBottom =[self.mapView convertPoint:CGPointMake(width, height) toCoordinateFromView:self];
    CLLocationCoordinate2D  pointCoords[4];
    CGFloat offset = 1;
    pointCoords[0] = CLLocationCoordinate2DMake(leftTop.latitude+offset, leftTop.longitude-offset);
    pointCoords[1] = CLLocationCoordinate2DMake(rightTop.latitude-offset, rightTop.longitude-offset);
    
    pointCoords[3] = CLLocationCoordinate2DMake(leftBottom.latitude+offset, leftBottom.longitude+offset);
    pointCoords[2] = CLLocationCoordinate2DMake(rightBottom.latitude-offset, rightBottom.longitude+offset);
    
    if (self.backMaskPolygon) {
        [self.mapView removeOverlay:self.backMaskPolygon];
    }
    
    MKPolygon* polygon = [MKPolygon polygonWithCoordinates:pointCoords count:4];
    self.backMaskPolygon = polygon;
    [self.mapView insertOverlay:self.backMaskPolygon atIndex:0 level:MKOverlayLevelAboveRoads];
}

/**  添加 开始结束定位大头针 */
-(void)showStartAndEndAnnotationLocation:(CLLocationCoordinate2D*)locations{
    
    if (self.mapView.annotations.count>0) {
        for (id<MKAnnotation> annotation in self.mapView.annotations) {
            if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
                if ([annotation.title isEqualToString:@"end"] ||
                    [annotation.title isEqualToString:@"start"]) {
                    [self.mapView removeAnnotation:annotation];
                }
            }
        }
    }
    
    {//start point
        CLLocationCoordinate2D coordinate=locations[0];
        MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
        pointAnnotation.coordinate = coordinate;
        pointAnnotation.title = @"start";
        pointAnnotation.subtitle=@"start";
        [self.mapView addAnnotation:pointAnnotation];
    }
    {//end point
        CLLocationCoordinate2D coordinate=locations[1];
        MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
        pointAnnotation.coordinate = coordinate;
        pointAnnotation.title = @"end";
        pointAnnotation.subtitle=@"end";
        [self.mapView addAnnotation:pointAnnotation];
    }
}


#pragma mark - ================ Delegate ==================
/**  地图区域改变时调用 */
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    /**  删除再重新加载的方式 不是太好 */
    //    [self.mapView removeFromSuperview];
    //    self.mapView = mapView;
    //    [self.view addSubview:mapView];
    
    [self setBackMask];
    if (fabs(self.currentSpan - mapView.region.span.latitudeDelta) > 0.04) {
        [self applyMapViewMemoryHotFix];
        self.currentSpan = mapView.region.span.latitudeDelta;
    }
}


/**  高德地图的GPS定位点 */
-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    self.currentLocation = userLocation.location;
    
    if (self.isFirst) {
        self.isFirst = NO;
        //经纬度的 跨度
        MKCoordinateSpan span = MKCoordinateSpanMake(0.003, 0.003);
        
        //显示的区域，由一个中心点 和 跨度决定
        MKCoordinateRegion region = MKCoordinateRegionMake(userLocation.coordinate, span);
        [mapView setRegion:region animated:YES];
    }
    
    /**  如果只开启地图定位，而不开启定位管理，程序不会在后台运行 */
    //    if (userLocation && !self.isWatchMode && self.isRun) {
    //        [self addTrackMapPoint:@[userLocation.location]];
    //    }
    if (self.tempBlock && self.currentLocation) {
        self.tempBlock(YES, @[@(self.currentLocation.coordinate.latitude), @(self.currentLocation.coordinate.longitude)]);
    }
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    if ([[overlay class] isSubclassOfClass:[GradientPolylineOverlay class]]) {
        GradientPolylineRenderer *polylineRenderer = [[GradientPolylineRenderer alloc] initWithOverlay:overlay];
        polylineRenderer.lineWidth = 8.f;
        return polylineRenderer;
        
//        MKPolylineRenderer* renderer = [[MKPolylineRenderer alloc]initWithPolyline:overlay];
//        renderer.fillColor = self.fillColor;
//        renderer.strokeColor = self.strokeColor;
//        renderer.lineWidth = self.lineWidth;
//        renderer.lineCap = kCGLineCapRound;
//        renderer.lineJoin = kCGLineJoinRound;
//        if ([[(MKPolyline*)overlay subtitle]isEqualToString:@"map"]) {
//            renderer.strokeColor = [UIColor greenColor];
//        }
//        return  renderer;
    }else if ([overlay isKindOfClass:[MKPolygon class]]){
        MKPolygonRenderer* renderer = [[MKPolygonRenderer alloc]initWithPolygon:(MKPolygon*)overlay];
        renderer.fillColor = [[UIColor blackColor]colorWithAlphaComponent:0.35];
        return  renderer;
    }
    
    return nil;
}
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
//        MKAnnotationView* pointView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"mapLocation"];
//        if (!pointView) {
//            pointView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"mapLocation"];
//            pointView.enabled = NO;
//            pointView.image = [UIImage imageNamed:@"mapLocation"];
//        }
//        return pointView;
        return nil;
    }else if ([annotation isKindOfClass:[MKPointAnnotation class]]){
        MKAnnotationView* pointView = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"point"];
        if (!pointView) {
            pointView = [[MKAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"point"];
            pointView.enabled = NO;
            pointView.centerOffset = CGPointMake(0, -14);
            pointView.image = nil;
        }
        if ([annotation.title isEqualToString:@"end"]) {
            pointView.image = [UIImage imageNamed:@"endPoint"];
            pointView.centerOffset = CGPointMake(10, -14);
            
        }else if([annotation.title isEqualToString:@"start"]){
            pointView.image = [UIImage imageNamed:@"startPoint"];
            pointView.centerOffset = CGPointMake(0, -14);
        }
        return pointView;
    }
    return  nil;
}

#pragma mark - ================ LocationDelegate ==================
/**  定位出来的火星GPS点  和高德坐标系有偏移*/
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations{
    
    if (locations.count && !self.isWatchMode && self.isRun) {
        CLLocation* location = locations.firstObject;
        
        //系统坐标系 -> 高德坐标系  有偏移
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude-0.003, location.coordinate.longitude+0.0049);
        location = [[CLLocation alloc]initWithCoordinate:coordinate altitude:location.altitude horizontalAccuracy:location.horizontalAccuracy verticalAccuracy:location.verticalAccuracy course:location.course speed:location.speed timestamp:location.timestamp];
        [self addTrackPoint:@[location]];
        if (self.tempBlock) {
            self.tempBlock(NO, @[@(location.coordinate.latitude), @(location.coordinate.longitude)]);
        }
        return;
    }
    if (self.tempBlock) {
        CLLocation* location = locations.firstObject;
        self.tempBlock(NO, @[@(location.coordinate.latitude), @(location.coordinate.longitude)]);
    }
}








@end
