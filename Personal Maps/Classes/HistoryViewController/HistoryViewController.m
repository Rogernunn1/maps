//
//  HistoryViewController.m
//  Personal Maps
//
//  Created by BBits on 15/12/17.
//  Copyright © 2017 Apple. All rights reserved.
//

#import "HistoryViewController.h"
#import "Sqlite.h"

@interface HistoryViewController ()

@end

@implementation HistoryViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"History";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [tblHistory reloadData];
}

#pragma mark - UITableView Methods

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section >=1)
    {
        return 0.5;
    }
    return 0.5;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([[ApplicationData sharedInstance].arrayStatistics count] == 0)
    {
        [tblHistory setHidden:YES];
        [lblNoHistory setHidden:NO];
    }
    else
    {
        [tblHistory setHidden:NO];
        [lblNoHistory setHidden:YES];
    }
    return [[ApplicationData sharedInstance].arrayStatistics count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HistoryTableCell *cell  =  [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"HistoryTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    // fetch data from object file and shows in label
    Run *runObj = [[ApplicationData sharedInstance].arrayStatistics objectAtIndex:indexPath.section];
    cell.lblHistoryLocations.text = [NSString stringWithFormat:@"%@",runObj.runName];
    cell.lblTime.text = [NSString stringWithFormat:@"%@",[runObj.runStartTimestamp substringFromIndex:11]];
    cell.lblDate.text = [NSString stringWithFormat:@"%@",[runObj.runStartTimestamp substringToIndex:10]];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
    Run *runObj = [[ApplicationData sharedInstance].arrayStatistics objectAtIndex:indexPath.section];
    MapViewController * mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
    mapViewController.runObj = runObj;
    [self.navigationController pushViewController:mapViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    Run * runObj = [[ApplicationData sharedInstance].arrayStatistics objectAtIndex:indexPath.section];
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        // delete data from database
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                       message:@"Are you sure you want to delete."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* OkAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  NSString *qryString = [NSString stringWithFormat:@"delete from Run where runID = '%@'",runObj.runID];
                                                                  [[ApplicationData sharedInstance] removeFile: runObj.locationFileName];
                                                                  [[ApplicationData sharedInstance].DBManager executeNonQuery:qryString];
                                                                  
                                                                  [[ApplicationData sharedInstance].arrayStatistics removeObjectAtIndex:indexPath.section];
                                                                  
                                                                  [tblHistory reloadData];
                                                              }];
        
        UIAlertAction* CancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [alert addAction:CancelAction];
        [alert addAction:OkAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
