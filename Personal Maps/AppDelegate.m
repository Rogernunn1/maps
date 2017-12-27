//
//  AppDelegate.m
// Personal Maps
//
//  Created by Apple on 19/05/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "ApplicationData.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self copyDBToDocument];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    MainViewController *controller = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    UINavigationController * navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [navController.navigationBar setTranslucent:NO];
    
    [[UINavigationBar appearance] setBarTintColor:ColorBlue];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor],NSForegroundColorAttributeName,
      [UIFont boldSystemFontOfSize:16.0], NSFontAttributeName,nil]];
    
    [self loadDefaultsValue];
    
    [self.window setRootViewController:navController];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self.window setNeedsDisplay];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    UIApplication *app = [UIApplication sharedApplication];
//    
//    //create new uiBackgroundTask
//    __block UIBackgroundTaskIdentifier bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
//        [app endBackgroundTask:bgTask];
//        bgTask = UIBackgroundTaskInvalid;
//    }];
    
    //and create new timer with async call:
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[ApplicationData sharedInstance] stopLocationService];
    
}

#pragma mark - Load defaults value

-(void) loadDefaultsValue
{
    
    if ([[ApplicationData sharedInstance].defaults boolForKey:isMilesON]) {
        [ApplicationData sharedInstance].isMilesOn = YES;
    }
    else
    {
        if ([[ApplicationData sharedInstance].defaults boolForKey:@"isFirstTimeMiles"]) {
            if ([[ApplicationData sharedInstance].defaults boolForKey:isMilesON]) {
                [ApplicationData sharedInstance].isMilesOn = YES;
            }
            else
            {
                [ApplicationData sharedInstance].isMilesOn = NO;
            }
        }
        else{
            [ApplicationData sharedInstance].isMilesOn = YES;
            [[ApplicationData sharedInstance].defaults setBool:YES forKey:@"isFirstTimeMiles"];
            [[ApplicationData sharedInstance].defaults setBool:YES forKey:isMilesON];
            
            [[ApplicationData sharedInstance].defaults synchronize];
            
        }
      
    }
    
    if ([[ApplicationData sharedInstance].defaults boolForKey:isShuffleON]) {
        [ApplicationData sharedInstance].isShuffleOn = YES;

        
    }
    else
    {
        if ([[ApplicationData sharedInstance].defaults boolForKey:@"isFirstTimeShuffle"]) {
            if ([[ApplicationData sharedInstance].defaults boolForKey:isShuffleON]) {
                [ApplicationData sharedInstance].isShuffleOn = YES;
             
            }
            else
            {
                [ApplicationData sharedInstance].isShuffleOn = NO;
             
            }
        }
        else{
            [ApplicationData sharedInstance].isShuffleOn = NO;
        
            [[ApplicationData sharedInstance].defaults setBool:YES forKey:@"isFirstTimeShuffle"];
            [[ApplicationData sharedInstance].defaults setBool:NO forKey:isShuffleON];
            [[ApplicationData sharedInstance].defaults synchronize];
        }
    }
    
}

#pragma mark - Copy database to document

- (void)copyDBToDocument {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *dbPath = [DOCUMENTS_FOLDER stringByAppendingPathComponent:@"personalmap.sqlite"];
    if ([fileManager fileExistsAtPath:dbPath] == NO) {
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"personalmap" ofType:@"sqlite"];
        [fileManager copyItemAtPath:resourcePath toPath:dbPath error:&error];
    }
}
@end
