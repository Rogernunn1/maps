//
//  ApplicationData.h
//  Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "AppConstants.h"
#import "MBProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import "Sqlite.h"

@protocol UpdateLocationDelegate <NSObject>
@optional
- (void)updateKmMiles:(NSString *)distance;

@end

@interface ApplicationData : NSObject<CLLocationManagerDelegate>
{
    
}
@property (nonatomic, assign) AppDelegate *appDelegate;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) Sqlite *DBManager;
@property(nonatomic,strong)id <UpdateLocationDelegate>delegate;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, readwrite) float distance;
@property (nonatomic, readwrite) float differenceDistance;

@property (nonatomic, assign) BOOL hasLocation;
@property (nonatomic, assign) BOOL isMilesOn;
@property (nonatomic, assign) BOOL isShuffleOn;
@property (nonatomic, retain) NSMutableArray *locationCoordinates;
@property (nonatomic, retain) NSMutableArray *arrayStatistics;
#pragma mark - Life Cycle of ApplicationData Methods
- (id)init;
+ (ApplicationData*)sharedInstance;
#pragma mark - MBProgressHUD Method
- (void)initHUD;
- (void)showHUD:(NSString *)text;
- (void)hideHUD;
- (void)startLocationUpdates;
- (void)stopLocationService;
- (BOOL)checkLocationPermission;
- (BOOL)removeFile:(NSString *)fileName;
-(BOOL) writeToTextFile:(NSString *)txtfileName contentString:(NSString *)content;
-(NSString *)readStringFromFile:(NSString *)txtfileName;
@end
