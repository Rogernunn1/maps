//
//  AppConstants.h
//  Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//


#define isPlaylistON        @"PlaylistOn"
#define isMilesON           @"isMilesON"
#define isShuffleON         @"isShuffleON"
#define metersInKM          1000;
#define metersInMile        1609.344;

#define iOS7 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
#define DOCUMENTS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

#define ColorBlue [UIColor colorWithRed:0.0/255.0 green:150.0/255.0 blue:255.0/255.0 alpha:1.0]
#define ColorGreen [UIColor colorWithRed:31.0/255.0 green:204.0/255.0 blue:102.0/255.0 alpha:1.0]
#define ColorText_Blue [UIColor colorWithRed:105.0/255.0 green:143.0/255.0 blue:167.0/255.0 alpha:1.0]
