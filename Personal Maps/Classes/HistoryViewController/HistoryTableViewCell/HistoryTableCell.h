//
//  HistoryTableCell.h
//  Personal Maps
//
//  Created by BBits on 15/12/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryTableCell : UITableViewCell

@property (nonatomic , strong) IBOutlet UILabel * lblHistoryLocations;
@property (nonatomic , strong) IBOutlet UILabel * lblTime;
@property (nonatomic , strong) IBOutlet UILabel * lblDate;

@end
