//
//  Location.m
//

#import "Location.h"
#import "Run.h"


@implementation Location

@synthesize latitude;
@synthesize longitude;
@synthesize timestamp;
@synthesize altitude;
@synthesize coordinate;
@synthesize firstObject;
@synthesize lastObject;
@synthesize lastUpdatedDate;

-(id)init{
    if(self = [super init])
    {
    }
    return self;
}
@end
