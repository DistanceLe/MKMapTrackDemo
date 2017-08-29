//
//  ViewController.m
//  MKMapDemo
//
//  Created by LiJie on 2017/2/9.
//  Copyright © 2017年 LiJie. All rights reserved.
//

#import "ViewController.h"
#import "LJMapTrackView.h"

#define IPHONE_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define IPHONE_WIDTH [[UIScreen mainScreen] bounds].size.width
#define kRGBColor(r, g, b, a)   [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define KSystemColor            kRGBColor(255, 192, 31, 1.0)


@interface ViewController ()

@property(nonatomic, strong)LJMapTrackView* trackView;
@property(nonatomic, assign)CLLocationCoordinate2D currentLocation;

@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@end

@implementation ViewController

-(void)dealloc{
    
    NSLog(@"...VC dealloc");
}
- (IBAction)rightClick:(UIBarButtonItem *)sender {

    
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"timeDemo://"]];
    
//    UIStoryboard* storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    ViewController* VC = [storyBoard instantiateViewControllerWithIdentifier:NSStringFromClass([ViewController class])];
//    
//    [self.navigationController pushViewController:VC animated:YES];
}

- (IBAction)phoneModel:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.trackView removeTrack];
        [sender setTitle:@"手机模式" forState:UIControlStateNormal];
        self.trackView.isWatchMode = NO;
    }else{
        [self.trackView removeTrack];
        [sender setTitle:@"手表模式" forState:UIControlStateNormal];
        self.trackView.isWatchMode = YES;
    }
}

- (IBAction)startRun:(UIButton *)sender {
    
    if (!self.trackView.isWatchMode) {
        [self.trackView startRun];
    }
}

- (IBAction)addRandomPoint:(UIButton *)sender {
    
    double latitude = self.currentLocation.latitude + arc4random()%100*0.000003;
    double longitude = self.currentLocation.longitude + arc4random()%100*0.000003;
    
    CLLocation* location = [[CLLocation alloc]initWithLatitude:latitude longitude:longitude];
    self.currentLocation = CLLocationCoordinate2DMake(latitude, longitude);
    [self.trackView addTrackPoint:@[location]];
    [self.trackView setMapCurrentLocation:location.coordinate];
}

-(void)writeToLog:(NSString*)log{
    NSString* currentStr = [NSString stringWithFormat:@"%@", self.contentTextView.text];
    currentStr = [currentStr stringByAppendingFormat:@"\n%@",log];
    self.contentTextView.text = currentStr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentLocation = CLLocationCoordinate2DMake(22.538307, 113.951341);
    
//    CLLocation* location0 = [[CLLocation alloc]initWithLatitude:22.538307 longitude:113.951341];
//    CLLocation* location1 = [[CLLocation alloc]initWithLatitude:22.548307 longitude:113.951341];
//    CLLocation* location2 = [[CLLocation alloc]initWithLatitude:22.538307 longitude:113.961341];
//    CLLocation* location3 = [[CLLocation alloc]initWithLatitude:22.538307 longitude:113.951341];
    
    self.trackView = [[LJMapTrackView alloc]initWithFrame:CGRectMake(20, 80, IPHONE_WIDTH-40, 200)];
    //[self.trackView addTrackPoint:@[location0, location1, location2, location3]];
    
    __weak typeof(self) tempWeakSelf=self;
    [self.trackView callBackHandler:^(BOOL isMapLoction, NSArray* value) {
        if (isMapLoction) {
            [tempWeakSelf writeToLog:[NSString stringWithFormat:@"++++++++++%.4f, %.4f", [value.firstObject floatValue], [value.lastObject floatValue]]];
        }else{
            [tempWeakSelf writeToLog:[NSString stringWithFormat:@"--%.4f, %.4f", [value.firstObject floatValue], [value.lastObject floatValue]]];
        }
    }];
    
    [self.view addSubview:self.trackView];
}


@end
