//
//  SMAppDelegate.h
//  SMILES
//
//  Created by asepmoels on 6/28/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@class SMViewController;
@class IIViewDeckController;
@class SMContactListPage;


@interface SMAppDelegate : UIResponder <UIApplicationDelegate>
{
    Reachability* internetReachable;
    BOOL internetActive;
    
    NSTimer * checkingTimer;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *viewController;
@property (strong, nonatomic) IIViewDeckController *mainViewController;
@property (strong, nonatomic) SMContactListPage *contactListPage;

@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) Reachability *wifiReachability;
-(BOOL)reachability;
@end
