//
//  MainViewController.h
//  Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "ApplicationData.h"
#import "Run.h"
#import "TWMessageBarManager.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MapKit/MapKit.h>
#import "MulticolorPolylineSegment.h"
#import "HistoryViewController.h"

@interface MainViewController : UIViewController<UpdateLocationDelegate,UIGestureRecognizerDelegate,UIAlertViewDelegate,MKMapViewDelegate>
{
    IBOutlet UIButton *btnStartStop;
    IBOutlet UILabel *lblKmMiles;
    IBOutlet MKMapView *mapViewLocation;
    IBOutlet UILabel *lblNoRun;
    
    NSString *uuid;
    NSMutableString *strLocation;
    NSString *strstartTime;
    NSString *strRunName;
    NSArray *arrLocations;

    

}
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (strong, nonatomic) NSDate *startDate; // Stores the date of the click on the start button
- (IBAction)btnStart_Pressed:(UIButton *)sender;
- (id)initWithStyleSheet:(NSObject<TWMessageBarStyleSheet> *)stylesheet;

@end
