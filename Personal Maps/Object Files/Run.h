//
//  Run.h
//  MoonRunner
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Run : NSObject

@property (nonatomic, retain) NSNumber * runID;
@property (nonatomic, retain) NSString * runDistance;
@property (nonatomic, retain) NSString * runStartTimestamp;
@property (nonatomic, retain) NSString * runStopTimestamp;
@property (nonatomic, retain) NSString * runName;


@property (nonatomic, retain) NSOrderedSet *locations;
@property (nonatomic, retain) Location *locationObj;

@property (nonatomic, retain) NSString *locationFileName;

-(id)init;
-(BOOL)insertIntoDB;
-(BOOL)deleteFromDatabase:(void (^)(bool result, NSError *error))completionHandler;

@end

