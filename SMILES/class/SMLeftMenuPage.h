//
//  SMLeftMenuPage.h
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMXMPPHandler.h"

@interface SMLeftMenuPage : UIViewController <SMXMPPHandlerDelegate>

@property (nonatomic, retain) NSMutableArray *notificationInfo;

-(void)reloadTableView;

@end
