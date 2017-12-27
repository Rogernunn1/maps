//
//  Run.m
//

#import "Run.h"
#import "Location.h"
#import "ApplicationData.h"

@implementation Run

@synthesize runID;
@synthesize runDistance;
@synthesize runStartTimestamp;
@synthesize runStopTimestamp;
@synthesize locations;
@synthesize locationObj;
@synthesize locationFileName;
@synthesize runName;

-(id)init{
    if(self = [super init])
    {
        locationObj = [[Location alloc] init];
    }
    return self;
}

#pragma mark - Insert into Database

-(BOOL)insertIntoDB {

    NSString *qryString = [NSString stringWithFormat:@"INSERT INTO Run (runDistance,runStartTimestamp,runStopTimestamp,locationFileName,altitude,runName) VALUES (\"%@\",\"%@\",\"%@\",\"%@\",\"%@\",\"%@\")",runDistance,runStartTimestamp,runStopTimestamp,locationFileName,@"",runName];
    
    @synchronized(self)
    {
        BOOL isInserted = NO;
        isInserted = [[ApplicationData sharedInstance].DBManager executeNonQuery:qryString];
        
        return isInserted;
    }
}


#pragma mark - Delete from database

-(BOOL)deleteFromDatabase:(void (^)(bool result, NSError *error))completionHandler{
    NSString *qryString = [NSString stringWithFormat:@"DELETE FROM Run WHERE runID = %@",runID];
    [[ApplicationData sharedInstance] removeFile:locationFileName];
    BOOL isSuccess = [[ApplicationData sharedInstance].DBManager executeNonQuery:qryString];
    completionHandler(isSuccess,nil);

    return isSuccess;
}
@end
