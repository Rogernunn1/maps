//
//  MapViewController.h
//  Personal Maps
//
//  Created by Apple on 09/06/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Run.h"
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController<MKMapViewDelegate>
{
    Run *runObj;
    NSArray *arrLocations;

}
@property(nonatomic,retain)Run *runObj;
@property (nonatomic, weak) IBOutlet MKMapView *mapsView;

@end
