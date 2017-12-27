//
//  MapViewController.m
//  Personal Maps
//
//  Created by Apple on 09/06/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "MapViewController.h"
#import "MathController.h"
#import "ApplicationData.h"
#import "Location.h"
#import "MulticolorPolylineSegment.h"
@interface MapViewController ()

@end

@implementation MapViewController
@synthesize runObj;
@synthesize mapsView;

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Map";
    arrLocations = [[NSArray alloc] init];
    self.mapsView.delegate = self;
                        // read sring from file
    arrLocations = [[[ApplicationData sharedInstance] readStringFromFile:runObj.locationFileName] componentsSeparatedByString:@","];
    [self loadMap];
}

#pragma mark - Load Map

- (void)loadMap
{
    if (arrLocations.count > 0) {
        
        // set the map bounds
        [self.mapsView setRegion:[self mapRegion]];
        // make the line(s!) on the map
        [self.mapsView addOverlays:[MathController colorSegmentsForLocations:arrLocations]];
    
    } else {
        
        // no locations were found!
        self.mapsView.hidden = YES;
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:@"Sorry, this walk has no locations saved."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
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
    [self.mapsView addAnnotation:initialLoc];
    
    CLLocationCoordinate2D cordinates;
    cordinates.latitude = lastobj.latitude;
    cordinates.longitude = lastobj.longitude;
    lastobj.coordinate = cordinates;
    lastobj.lastObject = @"End Point";
    [self.mapsView addAnnotation:lastobj];
    
    [self.mapsView showAnnotations:self.mapsView.annotations  animated:YES];
    
    region = [self.mapsView regionThatFits:region];
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
    Location *obj = (Location *)annotation;
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

#pragma mark - DidReceiveMemoryWarning

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
