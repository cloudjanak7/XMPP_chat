//
//  SMChatPage.h
//  SMILES
//
//  Created by asepmoels on 7/8/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMXMPPHandler.h"
@class XMPPRoom;

@interface SMChatPage : UIViewController

@property (nonatomic, copy) XMPPJID *withJID;
@property (nonatomic, copy) XMPPJID *myJID;
@property (nonatomic) BOOL groupChat;
@property (nonatomic) BOOL friendIsOnline;
@property (nonatomic, retain) XMPPRoom *room;

@end
