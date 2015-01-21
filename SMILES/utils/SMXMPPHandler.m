//
//  SMXMPPHandler.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMXMPPHandler.h"
#import "XMPP.h"
#import "XMPPReconnect.h"
#import "XMPPRoster.h"
#import "XMPPvCardTempModule.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPvCardCoreDataStorage.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPMessageArchiving.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessageDeliveryReceipts.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+MyCustom.h"
#import "XMPPvCardTemp.h"
#import "SMMyUserProfile.h"
#import "XMPPMUC.h"
#import "XMPPRoomCoreDataStorage.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "TURNSocket.h"
#import "XMPPAttentionModule.h"
#import "NSData+Base64.h"

#import "Define.h"

static SMXMPPHandler *handler = nil;

@interface SMXMPPHandler() <XMPPStreamDelegate, XMPPRosterDelegate, XMPPvCardTempModuleDelegate, XMPPvCardAvatarDelegate, XMPPRoomDelegate, XMPPMUCDelegate, UIActionSheetDelegate, TURNSocketDelegate>{
    XMPPStream *xmppStream;
    XMPPvCardTempModule *vCard;
    XMPPvCardAvatarModule *vCardAvatar;
    XMPPRoster *roster;
    XMPPMessageDeliveryReceipts *messageDelivery;
    XMPPReconnect *reconnect;
    XMPPMUC *muc;
    
    NSMutableArray *delegates;
    //NSMutableArray *groups;
    NSMutableArray *activeFriends;
}

@end

@implementation SMXMPPHandler

+(SMXMPPHandler *)XMPPHandler{
    if(!handler){
        handler = [[SMXMPPHandler alloc] init];
    }
    
    return handler;
}

#pragma mark - Instance Method

- (void)dealloc
{
    //[groups release];
    [delegates removeAllObjects];
    [xmppStream release];
    [vCard release];
    [delegates release];
    [roster release];
    [messageDelivery release];
    [reconnect release];
    [muc release];
    [activeFriends release];
    [super dealloc];
}

-(id)init{
    self = [super init];
    if(self){
        delegates = [[NSMutableArray alloc] init];
        //groups = [[NSMutableArray alloc] init];
        activeFriends = [[NSMutableArray alloc] init];
    }
    return self;
}

-(XMPPJID *)myJID{
    return xmppStream.myJID;
}

-(XMPPStream *)stream{
    return xmppStream;
}

-(void)addXMPPHandlerDelegate:(id<SMXMPPHandlerDelegate>)delegate{
    if(delegate && ![delegates containsObject:delegate])
        [delegates addObject:delegate];
}

-(void)removeAllXMPPHandlerDelegates{
    [delegates removeAllObjects];
}

-(void)removeXMPPHandlerDelegate:(id<SMXMPPHandlerDelegate>)delegate{
    if([delegates containsObject:delegate])
        [delegates removeObject:delegate];
}

-(void)setupXMPPConnection{
    xmppStream = [[XMPPStream alloc] init];
    
    reconnect = [[XMPPReconnect alloc] init];
    [reconnect addDelegate:self delegateQueue:dispatch_get_current_queue()];

    roster = [[XMPPRoster alloc] initWithRosterStorage:[XMPPRosterCoreDataStorage sharedInstance]];
    [roster setAutoFetchRoster:YES];
    [roster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [roster activate:xmppStream];

    vCard = [[XMPPvCardTempModule alloc] initWithvCardStorage:[XMPPvCardCoreDataStorage sharedInstance]];
    [vCard activate:xmppStream];
    [vCard addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    vCardAvatar = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:vCard];
    [vCardAvatar activate:xmppStream];
    [vCardAvatar addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    XMPPMessageArchiving *archive = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:[XMPPMessageArchivingCoreDataStorage sharedInstance] dispatchQueue:dispatch_get_main_queue()];
    [archive activate:xmppStream];
    [archive release];
    
    messageDelivery = [[XMPPMessageDeliveryReceipts alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    messageDelivery.autoSendMessageDeliveryRequests = YES;
    [messageDelivery activate:xmppStream];
    
    muc = [[XMPPMUC alloc] init];
    [muc addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [muc activate:xmppStream];
    
    [xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

-(BOOL)connect{
    if(!xmppStream)
        [self setupXMPPConnection];
    
    NSString *jabberID = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
    if (![xmppStream isDisconnected]) {
        return YES;
    }
    if (jabberID == nil) {
        return NO;
    }
    
    [xmppStream setMyJID:[XMPPJID jidWithUser:jabberID domain:@"lb1.smilesatme.com" resource:@"iphone"]];
    
    NSError *error = nil;
    if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[NSString stringWithFormat:@"Can't connect to server %@", [error localizedDescription]]
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        return NO;
    }
    NSLog(@"connect");
    [reconnect activate:xmppStream];
    
    return YES;
}

- (void)disconnect {
    [self goOffline];
    [xmppStream disconnect];
}

-(void)forceLogout{
    [self goOffline];
    [reconnect deactivate];
    [xmppStream disconnect];
}

- (void)goOnline {
    XMPPPresence *presence = [XMPPPresence presence];
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:xmppStream.myJID.user];
    [profile load];
    [presence addChild:[XMPPElement elementWithName:@"status" stringValue:profile.status]];
    [xmppStream sendElement:presence];
    
    [self discoverRoom];
}

- (void)goOffline {
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [xmppStream sendElement:presence];
}

-(void)notifyDelegateForType:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    NSMutableArray *tempDelegate = [NSMutableArray array];
    for(id one in delegates){
        [tempDelegate addObject:one];
    }
    for(id one in tempDelegate){
        if([one respondsToSelector:@selector(SMXMPPHandler:didFinishExecute:withInfo:)]){
            [one SMXMPPHandler:self didFinishExecute:type withInfo:info];
        }
    }
    [tempDelegate removeAllObjects];
}

- (void)sendMessage:(NSString *)_message to:(XMPPJID *)jid {
    NSString *messageID = [NSString stringWithFormat:@"%@_%@_%lf", self.myJID.bare, jid.bare, [[NSDate date] timeIntervalSince1970]];
    DDXMLElement *body = [DDXMLElement elementWithName:@"body" stringValue:_message];
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:jid elementID:messageID child:body];
    [message setDelivered:NO];
    [xmppStream sendElement:message];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"info", nil];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeChat withInfo:dict];
}

-(void)pow:(XMPPJID *)jid{
    /*<message id="37iqk-79" to="dheinaah@lb1.smilesatme.com" from="dheinaku@lb1.smilesatme.com/Spark 2.6.3">
    <attention xmlns="urn:xmpp:attention:0"/>
    <buzz xmlns="http://www.jivesoftware.com/spark"/>
    </message>*/
    
    NSString *messageID = [NSString stringWithFormat:@"%@_%@_%lf", self.myJID.bare, jid.bare, [[NSDate date] timeIntervalSince1970]];
    XMPPMessage *message = [XMPPMessage message];
    [message addAttributeWithName:@"id" stringValue:messageID];
    [message addAttributeWithName:@"to" stringValue:jid.bare];
    [message addChild:[DDXMLElement elementWithName:@"attention" xmlns:@"urn:xmpp:attention:0"]];
    [message addChild:[DDXMLElement elementWithName:@"buzz" xmlns:@"http://smilesatme.com/pow"]];
    [message setDelivered:NO];
    [xmppStream sendElement:message];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"info", nil];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeChat withInfo:dict];
}

-(void)sendChatState:(ChatState)state toJID:(XMPPJID *)toJid{
    XMPPMessage *message = [XMPPMessage messageWithType:@"chat" to:toJid];
    switch (state) {
        case ChatStateActive:
            [message addActiveChatState];
            break;
        case ChatStateComposing:
            [message addComposingChatState];
            break;
        case ChatStateGone:
            [message addGoneChatState];
            break;
        case ChatStateInactive:
            [message addInactiveChatState];
            break;
        case ChatStatePaused:
            [message addPausedChatState];
            break;
            
        default:
            break;
    }
    [xmppStream sendElement:message];
}

-(void)confirmDeliveryForMessage:(XMPPMessage *)_message{
    if(_message.hasReceiptRequest){
        XMPPMessageArchiving_Message_CoreDataObject *m = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getMessageWithID:_message.elementID];
        XMPPMessage *message = m.message;
        [message setDelivered:YES];
        m.messageStr = [NSString stringWithFormat:@"%@", message];
        [[XMPPMessageArchivingCoreDataStorage sharedInstance] insertMessage:m];
        
        XMPPMessage *newmessage = [_message generateReceiptResponse];
        [xmppStream sendElement:newmessage];
    }
}

-(void)sendStatusBroadcast:(NSString *)status{
    XMPPPresence *presence = [XMPPPresence presence];
    [presence addChild:[XMPPElement elementWithName:@"status" stringValue:status]];
    [xmppStream sendElement:presence];
}

-(void)sendAdminBroadcast:(NSString *)message{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLAdminBroadcast]];
    [request setPostValue:message forKey:@"message"];
    [request setPostValue:xmppStream.myJID.user forKey:@"username"];
    [request startAsynchronous];
    [request setCompletionBlock:^{
        NSDictionary *dict = [[request responseString] JSONValue];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[dict valueForKey:@"MESSAGE"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }];
}

-(void)addGroupName:(NSString *)name withJID:(XMPPJID *)jid andThumb:(UIImage *)thumb{
    XMPPvCardTemp *myvCard = [self myvCardTemp];
    NSMutableDictionary *dict = [myvCard.description JSONValue];
    
    NSMutableArray *group = nil;
    NSString *currentKey = nil;
    if([jid.domain rangeOfString:@"room"].length > 0){
        group = [dict valueForKey:kvCardDesRoomList];
        currentKey = kvCardDesRoomList;
    }else{
        group = [dict valueForKey:kvCardDesGroupList];
        currentKey = kvCardDesGroupList;
    }
    
    NSMutableDictionary *newObject = [NSMutableDictionary dictionary];
    NSInteger newIndex = 0;
    BOOL isNew = YES;
    for(NSMutableDictionary *dict in group){
        NSString *j = [dict valueForKey:kvCardDesJid];
        NSInteger index = [[dict valueForKey:kvCardDesId] integerValue];
        if([j isEqualToString:jid.bare]){
            newObject = dict;
            newIndex = index;
            isNew = NO;
            break;
        }
        
        if(newIndex <= index)
            newIndex = index + 1;
    }
    
    [newObject setValue:[NSNumber numberWithInteger:newIndex] forKey:kvCardDesId];
    [newObject setValue:jid.bare forKey:kvCardDesJid];
    [newObject setValue:name forKey:kvCardDesTitle];
    
    if(thumb){
        NSData *img = UIImageJPEGRepresentation(thumb, 0.7);
        [newObject setValue:[img base64EncodedString] forKey:kvCardDesThumb];
    }
    
    if(!group){
        group = [NSMutableArray array];
    }
    
    if(isNew){
        [group addObject:newObject];
    }

    if(!dict){
        dict = [NSMutableDictionary dictionary];
    }
    
    [dict setValue:group forKey:currentKey];
    
    myvCard.description = [dict JSONRepresentation];
    
    [self updateMyvCardTemp:myvCard];
}

-(void)removeGroupName:(NSString *)name withJID:(XMPPJID *)jid{
    XMPPvCardTemp *myvCard = [self myvCardTemp];
    NSMutableDictionary *dict = [myvCard.description JSONValue];
    
    NSMutableArray *group = nil;
    if([jid.domain rangeOfString:@"room"].length > 0){
        group = [dict valueForKey:kvCardDesRoomList];
    }else{
        group = [dict valueForKey:kvCardDesGroupList];
    }
    
    for(int i=0; i<group.count; i++){
        NSDictionary *dict = [group objectAtIndex:i];
        if([[[dict valueForKey:kvCardDesTitle] lowercaseString] isEqualToString:name]){
            [group removeObject:dict];
            break;
        }
    }
    
    myvCard.description = [dict JSONRepresentation];
    
    [self updateMyvCardTemp:myvCard];
}

#pragma mark - friend action

-(void)removeFriend:(NSString *)jid{
    if([jid componentsSeparatedByString:@"@"].count < 2)
        jid = [jid stringByAppendingString:@"@lb1.smilesatme.com"];
    
    XMPPJID *jjid = [XMPPJID jidWithString:jid];
    [roster removeUser:jjid];
    
    NSString *relcode = nil;
    for(NSDictionary *dict in activeFriends){
        if([[dict valueForKey:@"username"] isEqualToString:jjid.user]){
            relcode = [dict valueForKey:@"rel_code"];
        }
    }
    
    if(relcode){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendDelete]];
        [request setPostValue:xmppStream.myJID.user forKey:@"username"];
        [request setPostValue:relcode forKey:@"rel_code"];
        [request startAsynchronous];
    }
}

-(void)blockFriend:(XMPPJID *)jid block:(BOOL)yes{
    if(yes)
        [roster revokePresencePermissionFromUser:jid];
    else
        [roster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendBlock]];
    [request setPostValue:xmppStream.myJID.user forKey:@"username"];
    [request setPostValue:jid.user forKey:@"targetname"];
    [request setPostValue:yes?@"Y":@"N" forKey:@"flag"];
    [request startAsynchronous];
}

-(void)addFriend:(NSString *)jid withNickName:nick{
    XMPPJID *xjid = [XMPPJID jidWithString:jid];
    [roster addUser:xjid withNickname:nick groups:[NSArray arrayWithObjects:@"Friend", nil]];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendAdd]];
    [request setPostValue:xmppStream.myJID.user forKey:@"username"];
    [request setPostValue:xjid.user forKey:@"friendname"];
    [request setCompletionBlock:^{
        NSLog(@"add friend %@", [request responseString]);
        
        if([request.responseString rangeOfString:@"SUCCESS"].location == NSNotFound)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:ADD_FRIEND_BY_ID object:nil];
        }
    }];
    [request startAsynchronous];
}

-(void)acceptFriend:(XMPPJID *)jid{
    [roster acceptPresenceSubscriptionRequestFrom:jid andAddToRoster:YES];
    
    NSString *relcode = nil;
    for(NSDictionary *dict in activeFriends){
        if([[dict valueForKey:@"username"] isEqualToString:jid.user]){
            relcode = [dict valueForKey:@"rel_code"];
        }
    }
    
    NSLog(@"accept relcode %@", relcode);
    if(relcode){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendApprove]];
        [request setPostValue:xmppStream.myJID.user forKey:@"username"];
        [request setPostValue:relcode forKey:@"rel_code"];
        [request startAsynchronous];
    }
}

-(void)declineFriend:(XMPPJID *)jid{
    [roster rejectPresenceSubscriptionRequestFrom:jid];
    [roster removeUser:jid];
}

-(void)rejectFriend:(XMPPJID *)jid{
    [roster rejectPresenceSubscriptionRequestFrom:jid];
}

-(void)fetchRoster{
    [roster fetchRoster];
}

-(XMPPUserCoreDataStorageObject *)myUser{
    return [[XMPPRosterCoreDataStorage sharedInstance] myUserForXMPPStream:xmppStream];
}

-(XMPPUserCoreDataStorageObject *)userWithJID:(XMPPJID *)jid{
    return [[XMPPRosterCoreDataStorage sharedInstance] userForJID:jid xmppStream:xmppStream];
}

#pragma mark - delegate xmppStream
-(void)xmppStreamDidConnect:(XMPPStream *)sender{
    NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
    NSError *error;
    [xmppStream authenticateWithPassword:myPassword error:&error];
}

-(void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error{
    NSLog(@"disconnect %@", error);
    [self notifyDelegateForType:XMPPHandlerExecuteTypeDisconnect withInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, @"info", nil]];
}

-(void)xmppStreamDidAuthenticate:(XMPPStream *)sender{
    [self goOnline];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeLogin withInfo:nil];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendList]];
    [request setPostValue:sender.myJID.user forKey:@"username"];
    //[request setPostValue:sender.myJID.user forKey:@"username"];
    //[request setPostValue:[NSNumber numberWithInt:0] forKey:@"page"];
    [request setCompletionBlock:^{
        NSDictionary *result = [[request responseString] JSONValue];
        if([[result valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
            NSMutableArray *datas = [result valueForKey:@"DATA"];
            if(![datas isKindOfClass:[NSNull class]]){
                activeFriends = [datas retain];
            }
        }
    }];
    [request startAsynchronous];
}

-(void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error{
    [xmppStream disconnect];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeLoginFailed withInfo:nil];
}

-(void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message{
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:message, @"info", nil];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeChat withInfo:dict];
}

-(void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence{
    if([presence.type isEqualToString:@"subscribe"]){
        [self notifyDelegateForType:XMPPHandlerExecuteTypeFriendRequest withInfo:[NSDictionary dictionaryWithObjectsAndKeys:presence.from, @"jid", nil]];
    }else if([presence elementForName:@"status"]){
        [self notifyDelegateForType:XMPPHandlerExecuteTypeReceiveStatus withInfo:[NSDictionary dictionaryWithObjectsAndKeys:presence.from, @"jid", [[presence elementForName:@"status"] stringValue], @"status", nil]];
    }
}

-(XMPPPresence *)xmppStream:(XMPPStream *)sender willSendPresence:(XMPPPresence *)presence{
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:xmppStream.myJID.user];
    [profile load];
    DDXMLElement *el = [presence elementForName:@"status"];
    if(el){
        [el setStringValue:profile.status];
    }else{
        [presence addChild:[XMPPElement elementWithName:@"status" stringValue:profile.status]];
    }
    
    return presence;
}

-(XMPPvCardTemp *)vCardTemoForJID:(XMPPJID *)jid{
    return [[XMPPvCardCoreDataStorage sharedInstance] vCardTempForJID:jid xmppStream:xmppStream];
}

-(void)fetchvCardTemoForJID:(XMPPJID *)jid{
    [vCard fetchvCardTempForJID:jid ignoreStorage:YES];
}

-(XMPPvCardTemp *)myvCardTemp{
    return [vCard myvCardTemp];
}

-(void)updateMyvCardTemp:(XMPPvCardTemp *)vcard{
    [vCard updateMyvCardTemp:vcard];
}

#pragma mark - delegate XMPPRoster
-(void)xmppRosterDidEndPopulating:(XMPPRoster *)sender{
    NSArray *jids = [sender.xmppRosterStorage XMPPUserForXMPPStream:xmppStream];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeRoster withInfo:[NSDictionary dictionaryWithObject:jids forKey:@"info"]];

    for(XMPPUserCoreDataStorageObject *jid in jids){
        XMPPvCardTemp *temp = [[XMPPvCardCoreDataStorage sharedInstance] vCardTempForJID:jid.jid xmppStream:xmppStream];
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:[UIImage imageWithData:[temp photo]], @"photo", jid.jid.bare, @"jid", nil];
        NSDictionary *dict = [NSDictionary dictionaryWithObject:info forKey:@"info"];
        [self notifyDelegateForType:XMPPHandlerExecuteTypeAvatar withInfo:dict];
    }
}

-(void)xmppRoster:(XMPPRoster *)sender didRecieveRosterItem:(DDXMLElement *)item{
    [self performSelector:@selector(notifyRosterUpdate:) withObject:sender afterDelay:2.];
    
    NSString *username = [item attributeStringValueForName:@"jid"];
    XMPPJID *jid = [XMPPJID jidWithString:username];
    [vCard fetchvCardTempForJID:jid ignoreStorage:NO];
}

-(void)notifyRosterUpdate:(XMPPRoster *)sender{
    NSArray *jids = [sender.xmppRosterStorage XMPPUserForXMPPStream:xmppStream];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeRoster withInfo:[NSDictionary dictionaryWithObject:jids forKey:@"info"]];
}

-(NSArray *)allFriend{
    return [[XMPPRosterCoreDataStorage sharedInstance] XMPPUserForXMPPStream:xmppStream];
}

-(void)xmppRosterDidBeginPopulating:(XMPPRoster *)sender{
    
}

#pragma mark - delegate vCardTemp
-(void)xmppvCardTempModule:(XMPPvCardTempModule *)vCardTempModule didReceivevCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid{
    if(![jid isEqualToJID:xmppStream.myJID options:XMPPJIDCompareBare]){
        NSDictionary *root = [vCardTemp.description JSONValue];
        NSArray *groups = [root valueForKey:kvCardDesGroupList];
        for(NSDictionary *group in groups){
            NSData *dataImg = [NSData dataFromBase64String:[group valueForKey:kvCardDesThumb]];
            if(dataImg.length > 0){
                NSString *jid = [group valueForKey:kvCardDesJid];
                [self addAvatarGroupToMyvCard:[UIImage imageWithData:dataImg] toJID:jid];
            }
        }
    }
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:vCardTemp, @"vCard", jid.bare, @"jid", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:info forKey:@"info"];
    [self notifyDelegateForType:XMPPHandlerExecuteTypevCard withInfo:dict];
}

-(void)addAvatarGroupToMyvCard:(UIImage *)avatarImage toJID:(NSString *)jid{
    NSDictionary *root = [[[SMXMPPHandler XMPPHandler] myvCardTemp].description JSONValue];
    NSArray *groups = [root valueForKey:kvCardDesGroupList];
    for(NSDictionary *group in groups){
        NSString *jidG = [group valueForKey:kvCardDesJid];
        NSString *nameG = [group valueForKey:kvCardDesTitle];
        if([jidG isEqualToString:jid]){
            [self addGroupName:nameG withJID:[XMPPJID jidWithString:jidG] andThumb:avatarImage];
        }
    }
    //NSLog(@"hahaha %@", groups);
}

#pragma mark - delegate vCardAvatar
-(void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule didReceivePhoto:(UIImage *)photo forJID:(XMPPJID *)jid{
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:photo, @"photo", jid.bare, @"jid", nil];
    NSDictionary *dict = [NSDictionary dictionaryWithObject:info forKey:@"info"];
    [self notifyDelegateForType:XMPPHandlerExecuteTypeAvatar withInfo:dict];
}

#pragma mark - group
-(void)createGroup:(NSString *)groupname{
    if([groupname rangeOfString:@"@"].length < 1)
        groupname = [NSString stringWithFormat:@"%@@group.lb1.smilesatme.com", groupname];
    
    XMPPRoom *room = [[XMPPRoom alloc] initWithRoomStorage:[XMPPRoomCoreDataStorage sharedInstance] jid:[XMPPJID jidWithString:groupname]];
    [room addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [room activate:xmppStream];
    DDXMLElement *history = [DDXMLElement elementWithName:@"history"];
    [history addAttributeWithName:@"maxstanzas" stringValue:@"20"];
    [room joinRoomUsingNickname:xmppStream.myJID.user history:history];
    [room release];
}

-(void)sendGroupMessage:(NSString *)_message to:(XMPPJID *)jid{
    /*XMPPRoom *targetRoom = nil;
    for(XMPPRoom *room in groups){
        if([room.roomJID.bare isEqualToString:jid.bare]){
            targetRoom = room;
            break;
        }
    }
    if(targetRoom){
        [targetRoom sendMessage:_message];
        NSLog(@"kirim group message");
    }*/
}

-(void)xmppRoomDidCreate:(XMPPRoom *)sender{
    NSLog(@"Create Room");
}

-(void)xmppRoomDidJoin:(XMPPRoom *)sender{
    DDXMLElement *x = [DDXMLElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"muc#roomconfig_allowinvites"];
    [field addChild:[DDXMLElement elementWithName:@"value" stringValue:@"0"]];
    [x addChild:field];
    
    [sender configureRoomUsingOptions:x];
    
    NSLog(@"Join Room");
    [self notifyDelegateForType:XMPPHandlerExecuteTypeGroupReady withInfo:[NSDictionary dictionaryWithObjectsAndKeys:sender, @"sender", nil]];
}

-(void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSLog(@"ada yang join %@", occupantJID);
    [self notifyDelegateForType:XMPPHandlerExecuteTypeRoomActivity withInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@ did joined this group", [occupantJID.resource capitalizedString]], @"message", [NSDate date], @"timestamp", nil]];
    
    [self notifyDelegateForType:XMPPHandlerExecuteTypeGroupOccupantJoined withInfo:[NSDictionary dictionaryWithObjectsAndKeys:occupantJID, @"jid", sender, @"sender", nil]];
}

-(void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    [self notifyDelegateForType:XMPPHandlerExecuteTypeRoomActivity withInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@ did leave this group", [occupantJID.resource capitalizedString]], @"message", [NSDate date], @"timestamp", nil]];
}

-(void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitation:(XMPPMessage *)message{
    NSLog(@"dapet invitation %@ %@", roomJID, message);
    DDXMLElement *x = [[message children] objectAtIndex:0];
    DDXMLElement *invite = [x elementForName:@"invite"];
    DDXMLElement *reason = [invite elementForName:@"reason"];
    NSString *from = [[[invite attributeStringValueForName:@"from"] componentsSeparatedByString:@"@"] objectAtIndex:0];
    
    if (from == nil) {
        return;
    }
    
    NSString *strReason = [reason stringValue];
    NSArray *array = [strReason componentsSeparatedByString:@"info="];
    if (array && [array count] == 2) {
        NSString *strMsg = array[0];
        NSString *messageBody = [NSString stringWithFormat:@"Invitation to join \"%@\" group from %@ :\n%@", roomJID.user, from, strMsg];
        
        NSString *strRoomInof = array[1];
        NSArray *roomInfoArray = [strRoomInof componentsSeparatedByString:@"|"];
        if (roomInfoArray && [roomInfoArray count] == 2) {
            NSString *strAdminName = roomInfoArray[0];
            BOOL bOnlyInviteAdmin = [roomInfoArray[1] boolValue];

            [self notifyDelegateForType:XMPPHandlerExecuteTypeGroupReceiveInvitation withInfo:[NSDictionary dictionaryWithObjectsAndKeys:roomJID, @"jid", messageBody, @"message", [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@lb1.smilesatme.com", from]], @"from", strAdminName, @"adminusername", [NSNumber numberWithBool:bOnlyInviteAdmin], @"onlyinviteadmin", nil]];
        }
    }
}

-(void)xmppMUC:(XMPPMUC *)sender roomJID:(XMPPJID *)roomJID didReceiveInvitationDecline:(XMPPMessage *)message{
    NSLog(@"decline invitation %@", roomJID);
}

-(void)discoverRoom{
    DDXMLElement *iq = [XMPPIQ iqWithType:@"get" to:[XMPPJID jidWithString:@"room.lb1.smilesatme.com"] elementID:@"fkj23erkfd"];
    [iq addChild:[DDXMLElement elementWithName:@"query" xmlns:@"http://jabber.org/protocol/disco#items"]];
    [xmppStream sendElement:iq];
}

#pragma mark - file sending
-(void)sendFile:(NSString *)filename data:(NSData *)data mime:(NSString *)mime to:(XMPPJID *)jid{
    NSString *myID = [NSString stringWithFormat:@"IQ_%@_%@_%lf", xmppStream.myJID.bare, jid.bare, [NSDate timeIntervalSinceReferenceDate]];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" to:jid elementID:myID];
    
    DDXMLElement *si = [XMPPElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
    [si addAttributeWithName:@"mime-type" stringValue:mime];
    [si addAttributeWithName:@"profile" stringValue:@"http://jabber.org/protocol/si/profile/file-transfer"];
    [iq addChild:si];
    
    DDXMLElement *file = [XMPPElement elementWithName:@"file" xmlns:@"http://jabber.org/protocol/si/profile/file-transfer"];
    [file addAttributeWithName:@"name" stringValue:filename];
    [file addAttributeWithName:@"size" stringValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length]];
    [si addChild:file];
    
    DDXMLElement *feature = [XMPPElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
    [si addChild:feature];
    
    DDXMLElement *x = [XMPPElement elementWithName:@"x" xmlns:@"jabber:x:data"];
    [x addAttributeWithName:@"type" stringValue:@"form"];
    [feature addChild:x];
    
    DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
    [field addAttributeWithName:@"var" stringValue:@"stream-method"];
    [field addAttributeWithName:@"type" stringValue:@"list-single"];
    [x addChild:field];
    
    DDXMLElement *option = [DDXMLElement elementWithName:@"option"];
    [option addChild:[DDXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"]];
    [field addChild:option];
    
    [xmppStream sendElement:iq];
}
/*
 <iq type="set" to="asepmoels2@lb1.smilesatme.com/iphone" id="81A18D44-4F1E-4365-9794-B6C5DB3487C8"><query xmlns="http://jabber.org/protocol/bytestreams" sid="81A18D44-4F1E-4365-9794-B6C5DB3487C8" mode="tcp"><streamhost xmlns="http://jabber.org/protocol/bytestreams" jid="proxy.lb1.smilesatme.com" port="7777"/></query></iq>
 */
-(BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq{
    DDXMLElement *si = [iq elementForName:@"si"];
    NSString *queryXmlns = [iq elementForName:@"query"].xmlns;
    NSString *iqID = [iq elementID];
    
    if(si){
        if([iq.type isEqualToString:@"set"]){
            DDXMLElement *newIQ = [XMPPIQ iqWithType:@"result" to:iq.from elementID:iq.elementID];
            
            DDXMLElement *si = [XMPPElement elementWithName:@"si" xmlns:@"http://jabber.org/protocol/si"];
            [newIQ addChild:si];
            
            DDXMLElement *feature = [XMPPElement elementWithName:@"feature" xmlns:@"http://jabber.org/protocol/feature-neg"];
            [si addChild:feature];
            
            DDXMLElement *x = [XMPPElement elementWithName:@"x" xmlns:@"jabber:x:data"];
            [x addAttributeWithName:@"type" stringValue:@"submit"];
            [feature addChild:x];
            
            DDXMLElement *field = [DDXMLElement elementWithName:@"field"];
            [field addAttributeWithName:@"var" stringValue:@"stream-method"];
            [x addChild:field];
            [field addChild:[DDXMLElement elementWithName:@"value" stringValue:@"http://jabber.org/protocol/bytestreams"]];
            
            [xmppStream sendElement:newIQ];
        }else if([iq.type isEqualToString:@"result"]){
            TURNSocket *turn = [[TURNSocket alloc] initWithStream:xmppStream toJID:iq.from];
            [turn startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        }
        
        return YES;
    }else if([queryXmlns isEqualToString:@"http://jabber.org/protocol/bytestreams"] && [iq.type isEqualToString:@"set"]){
        TURNSocket *turn = [[TURNSocket alloc] initWithStream:xmppStream incomingTURNRequest:iq];
        [turn startWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        return YES;
    }else if([iqID isEqualToString:@"fkj23erkfd"]){
        DDXMLElement *query = [iq childElement];
        NSMutableArray *rooms = [NSMutableArray array];
        for(DDXMLElement *el in [query elementsForName:@"item"]){
            NSString *jid = [el attributeStringValueForName:@"jid"];
            NSString *name = [el attributeStringValueForName:@"name"];
            [rooms addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:jid, @"jid", name, @"name", nil]];
        }
        
        [self notifyDelegateForType:XMPPHandlerExecuteTypeDidDiscoverRoom withInfo:[NSDictionary dictionaryWithObjectsAndKeys:rooms, @"info", nil]];
        return YES;
    }
    
    return NO;
}

#pragma mark - delegate TURN socket
-(void)turnSocket:(TURNSocket *)sender didSucceed:(GCDAsyncSocket *)socket{
    NSLog(@"selesai");
}

-(void)turnSocketDidFail:(TURNSocket *)sender{
    NSLog(@"gagal");
}

@end
