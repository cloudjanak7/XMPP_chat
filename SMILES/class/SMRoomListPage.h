//
//  SMRoomListPage.h
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMRoomListPage : UIViewController

@property (nonatomic, unsafe_unretained) NSMutableArray *roomsData;

-(void)reloadView;

@end
