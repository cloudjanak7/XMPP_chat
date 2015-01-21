//
//  SMAppDelegate.m
//  SMILES
//
//  Created by asepmoels on 6/28/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMAppDelegate.h"
#import "XMPP.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "NSData+Base64.h"
#import "SMSplashScreen.h"
#import "IIViewDeckController.h"
#import "SMLeftMenuPage.h"
#import "SMContactListPage.h"
#import "SMRightMenuPage.h"
#import "SMAppConfig.h"
#import <CoreLocation/CoreLocation.h>
#import "SMPersistentObject.h"

@interface SMAppDelegate() <CLLocationManagerDelegate, UIAlertViewDelegate>{
    SMSplashScreen *splash;
    CLLocationManager *locationManager;
}

@end

@implementation SMAppDelegate

@synthesize window = _window, viewController = _viewController;
@synthesize mainViewController = _mainViewController;
@synthesize contactListPage;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [_mainViewController release];
    [contactListPage release];
    [locationManager release];
    [splash release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(userInfo != nil) {
        [self application:application didFinishLaunchingWithOptions:userInfo];
    }
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        self.window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        self.window.bounds = CGRectMake(0, 20, self.window.frame.size.width, self.window.frame.size.height);
        self.window.frame =  CGRectMake(0, 20, self.window.frame.size.width, self.window.frame.size.height);
    }

    splash = [[[SMSplashScreen alloc] init] autorelease];
    self.viewController = [[[UINavigationController alloc] initWithRootViewController:splash] autorelease];
    self.viewController.navigationBarHidden = YES;
    
    contactListPage = [[SMContactListPage alloc] init];
    
    self.mainViewController = [[[IIViewDeckController alloc] init] autorelease];
    self.mainViewController.leftController = [[[SMLeftMenuPage alloc] init] autorelease];
    self.mainViewController.centerController = self.contactListPage;
    self.mainViewController.rightController = [[[SMRightMenuPage alloc] init] autorelease];
    self.mainViewController.panningMode = IIViewDeckFullViewPanning;
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    [self performSelector:@selector(performUnresolvedChat) withObject:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //Change the host name here to change the server you want to monitor.

    self.internetReachability = [Reachability reachabilityForInternetConnection];
	[self.internetReachability startNotifier];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
	[self.wifiReachability startNotifier];
    internetActive = TRUE;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    //[self disconnect];
    [locationManager stopUpdatingLocation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    //[self connect];
    if([self.viewController.viewControllers lastObject] == splash)
        [splash checkConnection];
    [locationManager startUpdatingLocation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
    [SMAppConfig sharedConfig].deviceToken = [NSString stringWithFormat:@"%@", deviceToken];
    NSLog(@"My device token %@", [SMAppConfig sharedConfig].deviceToken);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
    NSLog(@"register notification error: %@", error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    
    NSLog(@"Notif %@", userInfo);
    NSDictionary *custome = [userInfo valueForKey:@"custome"];
    NSString *type = [custome valueForKey:@"type"];

    int badgeNumber = [[[userInfo objectForKey:@"aps"] objectForKey: @"badge"] intValue];
    if(badgeNumber> 0)
    {
        [UIApplication sharedApplication].applicationIconBadgeNumber += badgeNumber;
    }
    
    
    if([type isEqualToString:@"logout"]){
        [[SMXMPPHandler XMPPHandler] forceLogout];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Automatically Logged Out" message:@"You have logged in to another device." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }else if([type isEqualToString:@"visitor"]){
        NSDictionary *aps = [userInfo valueForKey:@"aps"];
        NSString *user = [[[aps valueForKey:@"alert"] componentsSeparatedByString:@" "] objectAtIndex:0];
        [[SMPersistentObject sharedObject] addNewVisitor:user];
        SMLeftMenuPage *menu = (SMLeftMenuPage *) self.mainViewController.leftController;
        [menu reloadTableView];
    }else if([type isEqualToString:@"myupdate"]){
        NSDictionary *aps = [userInfo valueForKey:@"aps"];
        NSString *user = [[[aps valueForKey:@"alert"] componentsSeparatedByString:@" "] objectAtIndex:0];
        NSArray *arrstr = [[aps valueForKey:@"alert"] componentsSeparatedByString:@" "];
        NSMutableArray *mtb = [NSMutableArray arrayWithArray:arrstr];
        [mtb removeObjectAtIndex:0];
        NSString *msg = [mtb componentsJoinedByString:@" "];
        [[SMPersistentObject sharedObject] addFriendsUpdate:user message:msg];
        SMLeftMenuPage *menu = (SMLeftMenuPage *) self.mainViewController.leftController;
        [menu reloadTableView];
    }else{
        NSDictionary *aps = [userInfo valueForKey:@"aps"];
        NSString *alert = [aps valueForKey:@"alert"];
        
        SMLeftMenuPage *menu = (SMLeftMenuPage *) self.mainViewController.leftController;
        if(!menu.notificationInfo){
            menu.notificationInfo = [NSMutableArray array];
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:alert, @"message", [NSDate date], @"timestamp", nil];
        [menu.notificationInfo insertObject:dict atIndex:0];
        [menu reloadTableView];
    }
}

#pragma mark - delegate CLLocation
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    SMAppConfig *config = [SMAppConfig sharedConfig];
    config.latitudeStr = [NSString stringWithFormat:@"%lf", newLocation.coordinate.latitude];
    config.longitudeStr = [NSString stringWithFormat:@"%lf", newLocation.coordinate.longitude];
}

#pragma mark - delegate alert
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"autosignin"];
    [self.viewController popToViewController:[self.viewController.viewControllers objectAtIndex:1] animated:YES];
    [alertView release];
}

-(void)performUnresolvedChat{
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(perform) userInfo:nil repeats:YES];
}
-(void)perform{
}
-(BOOL)reachability
{
    return internetActive;
}
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    
    switch (netStatus)
    {
        case NotReachable:        {
            internetActive = FALSE;
            break;
        }
            
        case ReachableViaWWAN:        {
            internetActive = TRUE;
            break;
        }
        case ReachableViaWiFi:        {
            internetActive = TRUE;
            break;
        }
    }

}
@end
