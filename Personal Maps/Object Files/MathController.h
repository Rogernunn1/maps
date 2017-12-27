//
//  MathController.h
//

#import <Foundation/Foundation.h>

@interface MathController : NSObject


+ (NSString *)stringifyDistance:(float)meters;

+ (NSString *)stringifySecondCount:(int)seconds usingLongFormat:(BOOL)longFormat;

//+ (NSString *)stringifyAvgPaceFromDist:(float)meters overTime:(int)seconds;

+ (NSString *)stringifyAveragePaceFromDist:(float)distance overTime:(int)milliSeconds;

+ (NSArray *)colorSegmentsForLocations:(NSArray *)locations;

+ (NSInteger )formatMilliSeconds:(NSUInteger)milliSeconds;

+ (NSString *)getTimeStringFromTime:(NSString *)strTime;
@end
