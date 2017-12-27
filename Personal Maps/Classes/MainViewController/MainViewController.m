//
//  MainViewController.m
//  Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "MainViewController.h"
#import "ApplicationData.h"
#import "Run.h"
#import "location.h"
#import "MathController.h"

@interface MainViewController ()

@end

@implementation MainViewController
@synthesize backgroundTask;

#pragma mark -TWMessageBarManager Mehod

- (id)initWithStyleSheet:(NSObject<TWMessageBarStyleSheet> *)stylesheet
{
    self = [super init];
    if (self)
    {
        [TWMessageBarManager sharedInstance].styleSheet = stylesheet;

    }
    return self;
}

#pragma mark -- Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mapViewLocation.delegate = self;
    arrLocations = [[NSArray alloc] init];
    self.title = @"Personal Maps";
    [ApplicationData sharedInstance].delegate = self;
    
    // TWMessageBarManager method (initWithStyleSheet)
    [self initWithStyleSheet:nil];
    
    UIBarButtonItem *brBtnInfo = [[UIBarButtonItem alloc] initWithTitle:@"History" style:UIBarButtonItemStylePlain target:self action:@selector(btnHistoryPressed)];
    [self.navigationItem setRightBarButtonItem:brBtnInfo];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    if ([[ApplicationData sharedInstance] checkLocationPermission]) {
        
    }
    else{
        [[ApplicationData sharedInstance] startLocationUpdates];
    }
    
    UIColor *tintColor = [UIColor orangeColor];
    [[UISlider appearance] setMinimumTrackTintColor:tintColor];

    lblKmMiles.text = [MathController stringifyDistance:0];

    btnStartStop.layer.cornerRadius = btnStartStop.frame.size.height/2;
    btnStartStop.clipsToBounds = YES;
    backgroundTask = UIBackgroundTaskInvalid;
    btnStartStop.backgroundColor = ColorBlue;
    lblKmMiles.text = [MathController stringifyDistance:0];
    
     //Shows start stop animation like heart for  startstop button
    [self heartAnimationStartStop];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Shows start stop animation like heart for  startstop button
    [self heartAnimationStartStop];
    // load data from database
    [self loadFromDatabase];
    if ([[ApplicationData sharedInstance].arrayStatistics count] > 0)
    {
        [self removeAllAnnotations];
        // Removes polylines from map
        [mapViewLocation removeOverlays:mapViewLocation.overlays];
        [mapViewLocation removeAnnotations:mapViewLocation.annotations];
        [mapViewLocation setHidden:NO];
        [lblNoRun setHidden:YES];
        Run * run = [[ApplicationData sharedInstance].arrayStatistics firstObject];
        arrLocations = [[[ApplicationData sharedInstance] readStringFromFile:run.locationFileName] componentsSeparatedByString:@","];
        [self loadMap:run];
    }
    else
    {
        [mapViewLocation setHidden:YES];
        [lblNoRun setHidden:NO];
    }

    if ([ApplicationData sharedInstance].distance > 0) {
        [self updateKmMiles:[NSString stringWithFormat:@"%f",[ApplicationData sharedInstance].distance]];
    }
}

#pragma mark - Remove Annotations Method

-(void)removeAllAnnotations
{
    id userAnnotation = mapViewLocation.userLocation;

    NSMutableArray *annotations = [NSMutableArray arrayWithArray:mapViewLocation.annotations];
    [annotations removeObject:userAnnotation];

    [mapViewLocation removeAnnotations:annotations];
}

#pragma mark - GestureRecognizer Method

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return  YES;
}

#pragma mark - Update Object in database

-(void)updateObject
{
    Run *runObj = [[Run alloc] init];
    [runObj setRunDistance:[NSString stringWithFormat:@"%2f",[ApplicationData sharedInstance].distance]];
    NSDateFormatter *df = [[NSDateFormatter alloc] init]; //Will release itself for us
    [df setDateFormat:@"dd-MM-yyyy hh:mm:ss a"];
    [runObj setRunStopTimestamp:[df stringFromDate:[NSDate date]]];
    [runObj setRunStartTimestamp:strstartTime];
    uuid = [[NSUUID UUID] UUIDString];
    [runObj setLocationFileName:uuid];
    [runObj setRunName:strRunName];
    
    strLocation = [[NSMutableString alloc] init];
    
    for (int j = 0; j< [[ApplicationData sharedInstance].locationCoordinates count]; j++) {
        CLLocation *newLocation = [[ApplicationData sharedInstance].locationCoordinates objectAtIndex:j] ;
        NSLog(@"%@",newLocation);
        if ([strLocation length] == 0) {
            [strLocation appendString:[NSString stringWithFormat:@"%f: %f",newLocation.coordinate.latitude,newLocation.coordinate.longitude]];
        }
        else {
            [strLocation appendString:@","];
            [strLocation appendString:[NSString stringWithFormat:@"%f:%f",newLocation.coordinate.latitude,newLocation.coordinate.longitude]];
        }
    }
    
    [[ApplicationData sharedInstance] stopLocationService];

    [btnStartStop setTitle:@"Start" forState:UIControlStateNormal];
    btnStartStop.backgroundColor = ColorBlue;    
    if (self.backgroundTask != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
    // write data to text file
    BOOL isStoredToFile = [[ApplicationData sharedInstance] writeToTextFile:uuid contentString:strLocation];
    if (isStoredToFile) {
        BOOL isSuccess = [runObj insertIntoDB];
        if (isSuccess) {
            [self resetData];
            
            //TWMessageBarManager method call
            [self successButtonPressed:@"Success!" Description:@"Data saved to history."];
        }
        else
        {
//            [[[UIAlertView alloc] initWithTitle:nil message:@"Failed to save data in statistics!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            //TWMessageBarManager method call
            [self errorButtonPressed:@"Error!" Description:@"Failed to save data in history."];
        }
    }
    else
    {
//        [[[UIAlertView alloc] initWithTitle:nil message:@"Failed to save data in statistics!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        //TWMessageBarManager method call
        [self errorButtonPressed:@"Error!" Description:@"Failed to save data in history."];

    }
}

#pragma mark - UIbutton Methods

-(void)btnHistoryPressed
{
    HistoryViewController * historyViewController = [[HistoryViewController alloc]initWithNibName:@"HistoryViewController" bundle:nil];
    [self.navigationController pushViewController:historyViewController animated:YES];
}

- (IBAction)btnStart_Pressed:(UIButton *)sender
{
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusAvailable)
    {
        if (!sender.selected)
        {
            sender.selected = YES;

            btnStartStop.backgroundColor = ColorGreen;
            NSDateFormatter *df = [[NSDateFormatter alloc] init]; //Will release itself for us
            [df setDateFormat:@"dd-MM-yyyy hh:mm:ss a"];
            self.startDate = [NSDate date];
            strstartTime = [df stringFromDate:[NSDate date]];
            [btnStartStop setTitle:@"Stop" forState:UIControlStateNormal];
            [[ApplicationData sharedInstance] startLocationUpdates];
        }
        else
        {
            sender.selected = NO;
              // AlertController with text field
            UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Walk"
                                                                                      message: @"Enter the name you want to show in history listing."
                                                                               preferredStyle:UIAlertControllerStyleAlert];
            [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"name";
                textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            }];
            
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                NSArray * textfields = alertController.textFields;
                UITextField * namefield = textfields[0];
                strRunName = namefield.text;
                // add data in database
                [self updateObject];
                //fetch data from database
                [self loadFromDatabase];
                if ([[ApplicationData sharedInstance].arrayStatistics count] > 0)
                {
                    [self removeAllAnnotations];
                    // Removes polylines from map
                    [mapViewLocation removeOverlays:mapViewLocation.overlays];
                    [mapViewLocation removeAnnotations:mapViewLocation.annotations];
                    [mapViewLocation setHidden:NO];
                    [lblNoRun setHidden:YES];
                    Run * run = [[ApplicationData sharedInstance].arrayStatistics firstObject];
                                    // read string from file
                    arrLocations = [[[ApplicationData sharedInstance] readStringFromFile:run.locationFileName] componentsSeparatedByString:@","];
                    [self loadMap:run];
                }
                else
                {
                    [mapViewLocation setHidden:YES];
                    [lblNoRun setHidden:NO];
                }
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied)
    {
        [[[UIAlertView alloc] initWithTitle:@"Enable Background App Refresh" message:@"Goto Settings app -> General -> Background App Refresh -> SetOn" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted)
    {
        [[[UIAlertView alloc] initWithTitle:@"Enable Background App Refresh" message:@"Goto Settings app -> General -> Background App Refresh -> SetOn" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    }
}

#pragma mark - Update KMMiles

-(void)updateKmMiles:(NSString *)distance
{
    lblKmMiles.text = [NSString stringWithFormat:@"%@",[MathController stringifyDistance:[distance floatValue]]];
}

#pragma mark - Heart Animation for start stop button method

-(void)heartAnimationStartStop
{
    CABasicAnimation *theAnimation;
    theAnimation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    theAnimation.duration=0.7;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:1.1];
    theAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [btnStartStop.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}

#pragma mark - Reset data

-(void)resetData
{
    [self heartAnimationStartStop];
    [[ApplicationData sharedInstance].locationCoordinates removeAllObjects];
    [ApplicationData  sharedInstance].distance = 0;
    lblKmMiles.text = [MathController stringifyDistance:0];
}

#pragma mark -- TWMessageBarManager Notificaiton

- (void)errorButtonPressed:(NSString *)title Description:(NSString *)description
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:title
                                                   description:description
                                                          type:TWMessageBarMessageTypeError
                                                statusBarStyle:UIStatusBarStyleLightContent
                                                      callback:nil];
}

- (void)successButtonPressed:(NSString *)title Description:(NSString *)description
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:title
                                                   description:description
                                                          type:TWMessageBarMessageTypeSuccess
                                                statusBarStyle:UIStatusBarStyleDefault
                                                      callback:nil];
}

- (void)infoButtonPressed:(NSString *)title Description:(NSString *)description
{
    [[TWMessageBarManager sharedInstance] showMessageWithTitle:title
                                                   description:description
                                                          type:TWMessageBarMessageTypeInfo
                                               statusBarHidden:YES
                                                      callback:nil];
}

#pragma mark -- didReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Load data From DataBase

-(void)loadFromDatabase
{
    NSString *qryString = [NSString stringWithFormat:@"SELECT * FROM Run"];
    NSMutableArray *list = [[NSMutableArray alloc] initWithArray:[[ApplicationData sharedInstance].DBManager executeQuery:qryString]];
    [[ApplicationData sharedInstance].arrayStatistics removeAllObjects];
    for (int i = 0; i<[list count]; i++)
    {
        Run *runObj = [[Run alloc] init];
        runObj.runDistance = [[list objectAtIndex:i] valueForKey:@"runDistance"];
        runObj.runID = [[list objectAtIndex:i] valueForKey:@"runID"];
        runObj.runStartTimestamp = [[list objectAtIndex:i] valueForKey:@"runStartTimestamp"];
        runObj.runStopTimestamp = [[list objectAtIndex:i] valueForKey:@"runStopTimestamp"];
        runObj.locationFileName =[[list objectAtIndex:i] valueForKey:@"locationFileName"];
       // runObj.locationObj.altitude =[[list objectAtIndex:i] valueForKey:@"altitude"];
        runObj.runName = [[list objectAtIndex:i] valueForKey:@"runName"];
        [[ApplicationData sharedInstance].arrayStatistics addObject:runObj];
    }
    [[ApplicationData sharedInstance].arrayStatistics sortUsingDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"runID" ascending:NO],nil]];

    [[ApplicationData sharedInstance] hideHUD];
}

#pragma mark - Load Map

- (void)loadMap:(Run *)runObj
{
    if ([ApplicationData sharedInstance].arrayStatistics.count > 0) {
        // set the map bounds
        [mapViewLocation setRegion:[self mapRegion]];
        // make the line(s!) on the map
        [mapViewLocation addOverlays:[MathController colorSegmentsForLocations:arrLocations]];
        
    } else {
        // no locations were found!
        mapViewLocation.hidden = YES;
        lblNoRun.hidden = NO;
    }
}

#pragma mark - MKMapViewDelegate

- (MKCoordinateRegion)mapRegion
{
    MKCoordinateRegion region;
    Location *initialLoc = [[Location alloc] init];
    initialLoc.latitude = [[[arrLocations.firstObject componentsSeparatedByString:@":"] firstObject] doubleValue];
    initialLoc.longitude = [[[arrLocations.firstObject componentsSeparatedByString:@":"] lastObject] doubleValue];

    Location *lastobj = [[Location alloc] init];
    lastobj.latitude = [[[arrLocations.lastObject componentsSeparatedByString:@":"] firstObject] doubleValue];
    lastobj.longitude = [[[arrLocations.lastObject componentsSeparatedByString:@":"] lastObject] doubleValue];

    float minLat = initialLoc.latitude;
    float minLng = initialLoc.longitude;
    float maxLat = initialLoc.latitude;
    float maxLng = initialLoc.longitude;
    
    for (int i = 0; i < [arrLocations count] ; i++) {
        Location *locationObj = [[Location alloc] init];
        locationObj.latitude = [[[[arrLocations objectAtIndex:i] componentsSeparatedByString:@":"] firstObject] doubleValue];
        locationObj.longitude = [[[[arrLocations objectAtIndex:i] componentsSeparatedByString:@":"] lastObject] doubleValue];
        NSLog(@"%@",[arrLocations objectAtIndex:i] );

        if (locationObj.latitude < minLat) {
            minLat = locationObj.latitude;
        }
        if (locationObj.longitude < minLng) {
            minLng = locationObj.longitude;
        }
        if (locationObj.latitude > maxLat) {
            maxLat = locationObj.latitude;
        }
        if (locationObj.longitude > maxLng) {
            maxLng = locationObj.longitude;
        }
    }
    // set start point and end point center on map
    region.center.latitude = (minLat + maxLat) / 2.0f;
    region.center.longitude = (minLng + maxLng) / 2.0f;
    
    region.span.latitudeDelta = (maxLat - minLat) * 1.1f;
    region.span.longitudeDelta = (maxLng - minLng) * 1.1f;
    
    // add annotation on start and end point
    CLLocationCoordinate2D cord;
    cord.latitude = initialLoc.latitude;
    cord.longitude = initialLoc.longitude;
    initialLoc.coordinate = cord;
    initialLoc.firstObject = @"Start Point";
    [mapViewLocation addAnnotation:initialLoc];
    
    CLLocationCoordinate2D cordinates;
    cordinates.latitude = lastobj.latitude;
    cordinates.longitude = lastobj.longitude;
    lastobj.coordinate = cordinates;
    lastobj.lastObject = @"End Point";
    [mapViewLocation addAnnotation:lastobj];
    
    [mapViewLocation showAnnotations:mapViewLocation.annotations  animated:YES];
    
    region = [mapViewLocation regionThatFits:region];

    return region;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if ([overlay isKindOfClass:[MulticolorPolylineSegment class]]) {
        MulticolorPolylineSegment *polyLine = (MulticolorPolylineSegment *)overlay;
        MKPolylineRenderer *aRenderer = [[MKPolylineRenderer alloc] initWithPolyline:polyLine];
        aRenderer.strokeColor = [UIColor redColor];//polyLine.color;
        aRenderer.lineWidth = 3;
        return aRenderer;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    Location *obj= (Location *)annotation;
    static NSString *annotationIdentifier = @"CustomViewAnnotation";
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;  //return nil to use default blue dot view
    MKAnnotationView* annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    if(!annotationView)
    {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:annotationIdentifier];
    }
    if([obj.firstObject isEqualToString:@"Start Point"])
    {
        annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"checkpoint"];
        annotationView.image = [UIImage imageNamed:@"viewMap.png"];
    }
    else if([obj.lastObject isEqualToString:@"End Point"])
    {
        annotationView=[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"checkpoint"];
        annotationView.image = [UIImage imageNamed:@"viewMap.png"];
    }
    return annotationView;
}

@end
