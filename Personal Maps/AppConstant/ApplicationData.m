
//  ApplicationData.m
//  Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "ApplicationData.h"
#import <CoreText/CoreText.h>
#import "MathController.h"

static ApplicationData *applicationData = nil;

@implementation ApplicationData

@synthesize HUD;
@synthesize appDelegate;
@synthesize delegate;
@synthesize locationManager;
@synthesize hasLocation;

@synthesize locationCoordinates;
@synthesize arrayStatistics;
@synthesize distance;
@synthesize DBManager;
@synthesize defaults;
@synthesize isMilesOn;
@synthesize isShuffleOn;
#pragma mark - Life Cycle of ApplicationData Methods

- (id)init
{
	if(self = [super init]) 
	{
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
        [self initHUD];
        defaults = [NSUserDefaults standardUserDefaults];
        arrayStatistics = [[NSMutableArray alloc] init];
        self.distance = 0;
        self.differenceDistance = 0;
        locationCoordinates = [NSMutableArray array];


        DBManager = [[Sqlite alloc] initWithFile:[DOCUMENTS_FOLDER stringByAppendingPathComponent:@"personalmap.sqlite"]];
        
    }
	return self;
}

+ (ApplicationData*)sharedInstance
{
    if (applicationData == nil)
    {
        applicationData = [[super allocWithZone:NULL] init];
    }
    return applicationData;
}

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

#pragma mark - MBProgressHUD Method
/*------------------------------------------------------------------
 Procedure/Function Name: initHUD
 Created By: Victor.
 Purpose: HUD Initialize
 ------------------------------------------------------------------*/
- (void)initHUD
{
    HUD = [[MBProgressHUD alloc] init];
    [appDelegate.window addSubview:HUD];
}

/*------------------------------------------------------------------
 Procedure/Function Name: showHUD
 Created By: Victor.
 Purpose: HUD SHow
 ------------------------------------------------------------------*/
- (void)showHUD:(NSString *)text
{
    HUD.labelText = text;
    [appDelegate.window bringSubviewToFront:HUD];
    [HUD show:YES];
}

/*------------------------------------------------------------------
 Procedure/Function Name: hideHUD
 Created By: Victor.
 Purpose: HUD Hide
 ------------------------------------------------------------------*/
- (void)hideHUD
{
    [HUD hide:YES];
}

#pragma mark - MYCLLocation
#pragma mark - CLLocationManagerDelegate
- (void)startLocationUpdates
{
    // Create the location manager if this object does not
    // already have one.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeFitness;
    
    // Movement threshold for new events.
    self.locationManager.distanceFilter = 10; // meters
    
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0){
        if([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
            [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        }
    }
    [self.locationManager startUpdatingLocation];
}

#pragma mark - DidUpdateLocation

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    for (CLLocation *newLocation in locations) {
        
        NSDate *eventDate = newLocation.timestamp;
        
        NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
        
        if (fabs(howRecent) < 10.0 && newLocation.horizontalAccuracy < 20) {
        
            // update distance
            if (self.locationCoordinates.count > 0) {
    
                // Distance in meters
                self.distance += [newLocation distanceFromLocation:self.locationCoordinates.lastObject];
                CLLocationCoordinate2D coords[2];
                coords[0] = ((CLLocation *)self.locationCoordinates.lastObject).coordinate;
                coords[1] = newLocation.coordinate;
                if ([delegate respondsToSelector:@selector(updateKmMiles:)]) {
                    [delegate updateKmMiles:[NSString stringWithFormat:@"%2f",self.distance]];
                }
            }
            NSLog(@"New Locations : %g", newLocation.altitude);
            [self.locationCoordinates addObject:newLocation];
        }
        if(newLocation.verticalAccuracy > 0)
        {
            if (self.locationCoordinates.count > 0)
            {
             NSLog(@"current altitude is: %g meters above sea level", newLocation.altitude);
             [self.locationCoordinates addObject:newLocation];
        }
    }
//        if(haveValidAltitude)
//        {
//            NSLog(@"current altitude is: %g meters above sea level", mostRecentLocation.altitude);
//        }else{
//            NSLog(@"current altitude is unavailable");
//        }
//        else {
//            if ([self.locationCoordinates count] == 0) {
//                [self.locationCoordinates addObject:newLocation];
//            }
//
//        }
    }
}

/*------------------------------------------------------------------
 Procedure/Function Name: stopLocationService
 Purpose: Stop Tracking Location
 ------------------------------------------------------------------*/
#pragma mark - Stop location service

- (void)stopLocationService {
    hasLocation = FALSE;
    [self.locationManager stopUpdatingLocation];
}


#pragma mark - Location Permission

- (BOOL) checkLocationPermission {
    // Get Status
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    // User has never been asked to decide on location authorization
    switch (status) {
            //        case kCLAuthorizationStatusNotDetermined:
            //        {
            //            NSLog(@"Requesting when in use auth");
            //            // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
            //            return NO;
            //
            //        }
            //            break;
        case kCLAuthorizationStatusDenied:
        {
            NSLog(@"Location services denied");
            return NO;
            
        }
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
        {
            return YES;
        }
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            return YES;
        }
        default:
            break;
    }
    return YES;
}


#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    switch (alertView.tag) {
        case 903:
        {
            if(buttonIndex == 1)
            {
                if(iOS7) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs://"]];
                }
                else if(UIApplicationOpenSettingsURLString)
                {
                    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Write to text file

-(BOOL) writeToTextFile:(NSString *)txtfileName contentString:(NSString *)content{
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/%@.txt",
                          documentsDirectory,txtfileName];
    //create content - four lines of text
    //save content to the documents directory
    BOOL isSaved = [content writeToFile:fileName
                             atomically:NO
                               encoding:NSUTF8StringEncoding
                                  error:nil];
    return isSaved;
}

#pragma mark - Remove file

- (BOOL)removeFile:(NSString *)fileName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@.txt",fileName]];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    return success;
}

#pragma mark - ReadingString from file

-(NSString *)readStringFromFile:(NSString *)txtfileName{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileAtPath = [filePath stringByAppendingString:[NSString stringWithFormat:@"/%@.txt",txtfileName]];
    return [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:fileAtPath] encoding:NSUTF8StringEncoding];
}
@end
