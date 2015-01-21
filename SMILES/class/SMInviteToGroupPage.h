//
//  SMInviteToGroupPage.h
//  SMILES
//
//  Created by asepmoels on 8/23/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XMPPRoom;

@interface SMInviteToGroupPage : UIViewController

@property (nonatomic, unsafe_unretained) XMPPRoom *room;

@end
