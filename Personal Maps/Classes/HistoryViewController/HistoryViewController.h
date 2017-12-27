//
//  HistoryViewController.h
//  Personal Maps
//
//  Created by BBits on 15/12/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HistoryTableCell.h"
#import "ApplicationData.h"
#import "Run.h"
#import "MapViewController.h"

@interface HistoryViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>
{
    IBOutlet UITableView * tblHistory;
    IBOutlet UILabel * lblNoHistory;
}

@end
