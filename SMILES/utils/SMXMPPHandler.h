//
//  SMXMPPHandler.h
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"

@class SMXMPPHandler, XMPPUserCoreDataStorageObject, XMPPMessageArchiving_Message_CoreDataObject, XMPPvCardTemp;

typedef enum {
    XMPPHandlerExecuteTypeLogin,
    XMPPHandlerExecuteTypeLoginFailed,
    XMPPHandlerExecuteTypeDisconnect,
    XMPPHandlerExecuteTypeRoster,
    XMPPHandlerExecuteTypeAvatar,
    XMPPHandlerExecuteTypeChat,
    XMPPHandlerExecuteTypevCard,
    XMPPHandlerExecuteTypeFriendRequest,
    XMPPHandlerExecuteTypeReceiveStatus,
    XMPPHandlerExecuteTypeGroupReady,
    XMPPHandlerExecuteTypeGroupReceiveInvitation,
    XMPPHandlerExecuteTypeGroupOccupantJoined,
    XMPPHandlerExecuteTypeDidDiscoverRoom,
    XMPPHandlerExecuteTypeRoomActivity,
} XMPPHandlerExecuteType;

typedef enum{
    ChatStateActive,
    ChatStateComposing,
    ChatStatePaused,
    ChatStateInactive,
    ChatStateGone
} ChatState;

@protocol SMXMPPHandlerDelegate <NSObject>
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info;
@end

@interface SMXMPPHandler : NSObject

+(SMXMPPHandler *)XMPPHandler;

-(XMPPJID *)myJID;
-(XMPPStream *)stream;
-(BOOL)connect;
-(void)disconnect;
-(void)addXMPPHandlerDelegate:(id<SMXMPPHandlerDelegate>)delegate;
-(void)removeXMPPHandlerDelegate:(id<SMXMPPHandlerDelegate>)delegate;
-(void)removeAllXMPPHandlerDelegates;
-(void)sendMessage:(NSString *)_message to:(XMPPJID *)jid ;
-(void)forceLogout;
-(void)pow:(XMPPJID *)jid;

-(void)removeFriend:(NSString *)jid;
-(void)addFriend:(NSString *)jid withNickName:nick;
-(void)acceptFriend:(XMPPJID *)jid;
-(void)declineFriend:(XMPPJID *)jid;
-(void)fetchRoster;
-(XMPPUserCoreDataStorageObject *)myUser;
-(void)rejectFriend:(XMPPJID *)jid;
-(void)blockFriend:(XMPPJID *)jid block:(BOOL)yes;
-(XMPPUserCoreDataStorageObject *)userWithJID:(XMPPJID *)jid;
-(void)sendChatState:(ChatState)state toJID:(XMPPJID *)toJid;
-(void)confirmDeliveryForMessage:(XMPPMessage *)message;
-(void)sendStatusBroadcast:(NSString *)status;
-(NSArray *)allFriend;

-(XMPPvCardTemp *)vCardTemoForJID:(XMPPJID *)jid;
-(void)fetchvCardTemoForJID:(XMPPJID *)jid;
-(XMPPvCardTemp *)myvCardTemp;
-(void)updateMyvCardTemp:(XMPPvCardTemp *)vcard;

-(void)createGroup:(NSString *)groupname;
-(void)sendGroupMessage:(NSString *)_message to:(XMPPJID *)jid ;

-(void)sendAdminBroadcast:(NSString *)message;
-(void)sendFile:(NSString *)filename data:(NSData *)data mime:(NSString *)mime to:(XMPPJID *)jid;

-(void)addGroupName:(NSString *)name withJID:(XMPPJID *)jid andThumb:(UIImage *)thumb;
-(void)removeGroupName:(NSString *)name withJID:(XMPPJID *)jid;

@end
