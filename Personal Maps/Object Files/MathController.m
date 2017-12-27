//
//  MathController.m
//

#import "MathController.h"
#import "Location.h"
#import "MulticolorPolylineSegment.h"
#import <CoreLocation/CoreLocation.h>
#import "ApplicationData.h"

static const int idealSmoothReachSize = 33; // about 133 locations/mi

@implementation MathController

#pragma mark - Format miliseconds

+ (NSInteger )formatMilliSeconds:(NSUInteger)milliSeconds
{
    NSUInteger sec = ((milliSeconds % (100 * 60 * 60)) % (100 * 60)) / 100;
  
    return sec;
}

#pragma mark - StringifyDistance

+ (NSString *)stringifyDistance:(float)meters {
    
    float unitDivider;
    NSString *unitName;
    
    
    if (![ApplicationData sharedInstance].isMilesOn) {
        
        unitName = @"Km";
        
        // to get from meters to kilometers divide by this
        unitDivider = metersInKM;
        
        // U.S.
    } else {
        
        unitName = @"Miles";
        
        // to get from meters to miles divide by this
        unitDivider = metersInMile;
    }
    
    return [NSString stringWithFormat:@"%.2f %@", (meters / unitDivider), unitName];
}

#pragma mark - StringifySecondCount

+ (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat {
    
    int remainingSeconds = seconds;
    
    int hours = remainingSeconds / 3600;
    
    remainingSeconds = remainingSeconds - hours * 3600;
    
    int minutes = remainingSeconds / 60;
    
    remainingSeconds = remainingSeconds - minutes * 60;
    
    if (longFormat) {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%ihr %imin %isec", hours, minutes, remainingSeconds];
            
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%imin %isec", minutes, remainingSeconds];
            
        } else {
            return [NSString stringWithFormat:@"%isec", remainingSeconds];
        }
    } else {
        if (hours > 0) {
            return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, remainingSeconds];
            
        } else if (minutes > 0) {
            return [NSString stringWithFormat:@"%02i:%02i", minutes, remainingSeconds];
            
        } else {
            return [NSString stringWithFormat:@"00:%02i", remainingSeconds];
        }
    }
}

#pragma mark - Get timestring from time

+ (NSString *)getTimeStringFromTime:(NSString *)strTime{
    NSString *t1, *t2, *t = @"00:00";
    int hour = 0, min = 0;
    long time = 0,seconds = 0;
    if ([strTime rangeOfString:@":"].location != NSNotFound) {
        
        t1 = [[strTime componentsSeparatedByString:@":"] firstObject];
        t2 = [[strTime componentsSeparatedByString:@":"] lastObject];
        
        time = abs(([t1 intValue]-[t2 intValue]));
        if (time < 60) {
            seconds = time;
        }
        else {
            min = (time / 60);
            seconds = (time % 60);
            if (min >= 60) {
                hour = (min / 60);
                min = (min % 60);
            }
        }
        
        t = [NSString stringWithFormat:@"%02d:%02ld",min,seconds];
    }
    return t;
}

#pragma mark - StringifyAveragePaceFromDist

+ (NSString *)stringifyAveragePaceFromDist:(float)distance overTime:(int)milliSeconds {
    
    // V: convert meter to km or miles
    NSString *unitName;
    float unitDivider = 0.0;
    if (![ApplicationData sharedInstance].isMilesOn) {
        unitName = @"min/km";
        unitDivider = metersInKM;
    } else {
        unitName = @"min/Mile";
        unitDivider = metersInMile;
    }
    
    distance = distance/unitDivider;

    float avgSpeed = (milliSeconds / distance);
    
    float paceSecond = (long)avgSpeed % 60;
    int paceMin =  (avgSpeed / 60);
    
    if (milliSeconds == 0 || distance == 0) {
        return [NSString stringWithFormat:@"00:00 %@",unitName];
    }
    
    return [NSString stringWithFormat:@"%d:%02.0f %@",paceMin,paceSecond, unitName];
}

#pragma mark - Color segments for locations

+ (NSArray *)colorSegmentsForLocations:(NSArray *)locations
{
    if (locations.count == 1){
        Location *loc = [[Location alloc] init];
        
        loc.latitude = [[[locations.firstObject componentsSeparatedByString:@":"] firstObject] doubleValue];
        loc.longitude = [[[locations.firstObject componentsSeparatedByString:@":"] lastObject] doubleValue];
        
        CLLocationCoordinate2D coords[2];
        coords[0].latitude      = loc.latitude;
        coords[0].longitude     = loc.longitude;
        coords[1].latitude      = loc.latitude;
        coords[1].longitude     = loc.longitude;
        
        MulticolorPolylineSegment *segment = [MulticolorPolylineSegment polylineWithCoordinates:coords count:2];
        segment.color = [UIColor blackColor];
        return @[segment];
    }
    
    // make array of all speeds
    NSMutableArray *rawSpeeds = [NSMutableArray array];
    
    for (int i = 1; i < locations.count; i++) {
        //        Location *firstLoc = [locations objectAtIndex:(i-1)];
        //        Location *secondLoc = [locations objectAtIndex:i];
        
        Location *firstLoc = [[Location alloc] init];
        Location *secondLoc = [[Location alloc] init];
        
        
        firstLoc.latitude = [[[[locations objectAtIndex:(i-1)] componentsSeparatedByString:@":"] firstObject] doubleValue];
        firstLoc.longitude = [[[[locations objectAtIndex:(i-1)] componentsSeparatedByString:@":"] lastObject] doubleValue];
        
        secondLoc.latitude = [[[[locations objectAtIndex:i] componentsSeparatedByString:@":"] firstObject] doubleValue];
        secondLoc.longitude = [[[[locations objectAtIndex:i] componentsSeparatedByString:@":"] lastObject] doubleValue];
        
        
        CLLocation *firstLocCL = [[CLLocation alloc] initWithLatitude:firstLoc.latitude longitude:firstLoc.longitude];
        CLLocation *secondLocCL = [[CLLocation alloc] initWithLatitude:secondLoc.latitude longitude:secondLoc.longitude];
        
        double distance = [secondLocCL distanceFromLocation:firstLocCL];
        double time = [secondLoc.timestamp timeIntervalSinceDate:firstLoc.timestamp];
        double speed = distance/time;
        
        [rawSpeeds addObject:[NSNumber numberWithDouble:speed]];
    }
    
    // smooth the raw speeds
    NSMutableArray *smoothSpeeds = [NSMutableArray array];
    
    for (int i = 0; i < rawSpeeds.count; i++) {
        
        // set to ideal size
        int lowerBound = i - idealSmoothReachSize / 2;
        int upperBound = i + idealSmoothReachSize / 2;
        
        // scale back reach as necessary
        if (lowerBound < 0) {
            lowerBound = 0;
        }
        
        if (upperBound > ((int)rawSpeeds.count - 1)) {
            upperBound = (int)rawSpeeds.count - 1;
        }
        
        // define range for average
        NSRange range;
        range.location = lowerBound;
        range.length = upperBound - lowerBound;
        
        // get values to average
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
        NSArray *relevantSpeeds = [rawSpeeds objectsAtIndexes:indexSet];
        
        double total = 0.0;
        
        for (NSNumber *speed in relevantSpeeds) {
            total += speed.doubleValue;
        }
        
        double smoothAverage = total / (double)(upperBound - lowerBound);
        
        [smoothSpeeds addObject:[NSNumber numberWithDouble:smoothAverage]];
    }
   
    NSMutableArray *colorSegments = [NSMutableArray array];
    
    for (int i = 1; i < locations.count; i++) {
      
        Location *firstLoc = [[Location alloc] init];
        Location *secondLoc = [[Location alloc] init];
        
        
        firstLoc.latitude = [[[[locations objectAtIndex:(i-1)] componentsSeparatedByString:@":"] firstObject] doubleValue];
        firstLoc.longitude = [[[[locations objectAtIndex:(i-1)] componentsSeparatedByString:@":"] lastObject] doubleValue];
        
        secondLoc.latitude = [[[[locations objectAtIndex:i] componentsSeparatedByString:@":"] firstObject] doubleValue];
        secondLoc.longitude = [[[[locations objectAtIndex:i] componentsSeparatedByString:@":"] lastObject] doubleValue];
        
        CLLocationCoordinate2D coords[2];
        coords[0].latitude = firstLoc.latitude;
        coords[0].longitude = firstLoc.longitude;
        
        coords[1].latitude = secondLoc.latitude;
        coords[1].longitude = secondLoc.longitude;
        
        MulticolorPolylineSegment *segment = [MulticolorPolylineSegment polylineWithCoordinates:coords count:2];
        segment.color = [UIColor redColor];
        
        [colorSegments addObject:segment];
    }
    
    return colorSegments;
}

@end

