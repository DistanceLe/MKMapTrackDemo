//
//  LJMapTrackView.h
//  MKMapDemo
//
//  Created by LiJie on 2017/2/9.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

typedef void(^MapLocationBlock)(BOOL isMapLoction, id value);

@interface LJMapTrackView : UIView

/**  填充颜色 默认绿色 */
@property(nonatomic, strong)UIColor* fillColor;

/**  路径的颜色 默认红色 */
@property(nonatomic, strong)UIColor* strokeColor;

/**  路径的宽度 默认是5 */
@property(nonatomic, assign)CGFloat  lineWidth;

/**  是否为手表模式， 默认是（即定位点 为手表传过来的） */
@property(nonatomic, assign)BOOL  isWatchMode;

/**  定位服务没有打开时，可以手动设置当前地图的位置 */
-(void)setMapCurrentLocation:(CLLocationCoordinate2D)coordinate;

/**  不是手表模式时，调用该方法，开始绘制运动路径 */
-(void)startRun;

/**  不是手表模式时，调用该方法，结束绘制运动路径 */
-(void)stopRun;


/**  在路径上增加路径 ，增加点 */
-(void)addTrackPoint:(NSArray<CLLocation*>*)coordinates;

/**  删除路径 */
-(void)removeTrack;


/**  定位的回调， 地图的定位 是高德的坐标系。 locationManager的定位 是系统的坐标系。 两者 有偏移。 */
-(void)callBackHandler:(MapLocationBlock)handler;


@end
