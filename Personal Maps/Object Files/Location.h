//
//  Location.h
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>


@interface Location : NSObject<MKAnnotation>
{
    
}
@property (nonatomic, readwrite) double latitude;
@property (nonatomic, readwrite) double longitude;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * altitude;
@property (nonatomic, assign)    CLLocationCoordinate2D    coordinate;
@property (nonatomic, retain)NSString *firstObject;
@property (nonatomic, retain)NSString *lastObject;
@property (nonatomic, retain)NSDate   *lastUpdatedDate;

-(id)init;
@end
