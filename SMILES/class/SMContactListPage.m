//
//  SMContactListPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMContactListPage.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "SMChatPage.h"
#import "SMFriendsCell.h"
#import "SMHeaderContactView.h"
#import "UIColor+utils.h"
#import "IIViewDeckController.h"
#import "SMAppDelegate.h"
#import "SMRecentChatCell.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+MyCustom.h"
#import "XMPPvCardTemp.h"
#import "XMPPResourceCoreDataStorageObject.h"
#import "XMPPRoom.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPMessage+XEP_0224.h"
#import "SMPersistentObject.h"
#import "XMPPMessage+MyCustom.h"
#import "JSON.h"
#import "SMAppConfig.h"
#import "NSData+Base64.h"
#import "XMPPRoomCoreDataStorage.h"

typedef enum {
    GroupTypeChats = 0,
    GroupTypeFriends,
    GroupTypeGroups,
    GroupTypeRooms
} GroupType;

@interface SMContactListPage () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>{
    IBOutlet UITableView *tableView;
    IBOutlet UITextField *searchField;
    
    NSMutableDictionary *tableData;
    NSString *currentChatFriendsBare;
    NSMutableArray *powedCell;
    NSTimer *powTimer;
    NSArray *emoticonsData;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;
-(IBAction)hideKeyboard:(id)sender;

@property (nonatomic, retain) NSMutableArray *tempFriendsData;

@end

@implementation SMContactListPage

@synthesize tempFriendsData;

- (void)dealloc
{
    [tableData release];
    [currentChatFriendsBare release];
    [tempFriendsData release];
    [powedCell release];
    [emoticonsData release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    powedCell = [[NSMutableArray alloc] init];
    tableData = [[NSMutableDictionary alloc] init];
    emoticonsData = [[[SMPersistentObject sharedObject] emoticonsGrouped:NO] retain];
    
    [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:[SMXMPPHandler XMPPHandler].myJID];
    
    self.view.backgroundColor = [UIColor colorWithWhite:243/255. alpha:1.];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(currentChatFriendsBare){
        [self resetUnreadMessageForBare:currentChatFriendsBare];
        [currentChatFriendsBare release];
        currentChatFriendsBare = nil;
    }
    
    /*
    NSString *mainKey = [NSString stringWithFormat:@"%d", GroupTypeChats];
    NSMutableDictionary *parent = [tableData valueForKey:mainKey];
    NSMutableArray *mainCollection = [parent valueForKey:@"content"];
    NSMutableArray *toDeletes = [NSMutableArray array];
    for(XMPPMessageArchiving_Message_CoreDataObject *m in mainCollection){
        if(m.messageStr.length < 1){
            [toDeletes addObject:m];
        }
    }
    [mainCollection removeObjectsInArray:toDeletes];
    */
    [tableView reloadData];
}

#pragma mark - Action
-(void)hideKeyboard:(id)sender{
    [searchField resignFirstResponder];
}

-(void)openLeftMenu:(id)sender{
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.mainViewController toggleLeftViewAnimated:YES completion:^(IIViewDeckController *controller) {
        
    }];
}

-(void)openRightMenu:(id)sender{
    
//    for(XMPPUserCoreDataStorageObject *obj in self.tempFriendsData){
//        [[SMXMPPHandler XMPPHandler] removeFriend:obj.jid.user];
//    }
//    
//    //[self.tempFriendsData removeAllObjects];
//    [[SMXMPPHandler XMPPHandler] fetchRoster];
//    [tableView reloadData];
//
//    return;

    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.mainViewController toggleRightViewAnimated:YES completion:^(IIViewDeckController *controller) {
        
    }];
}

-(void)resetUnreadMessageForBare:(NSString *)bare{
    NSString *mainKey = [NSString stringWithFormat:@"%d", GroupTypeChats];
    NSMutableDictionary *parent = [tableData valueForKey:mainKey];
    NSMutableArray *mainCollection = [parent valueForKey:@"content"];
    
    XMPPMessageArchiving_Message_CoreDataObject *target = nil;
    for(XMPPMessageArchiving_Message_CoreDataObject *m in mainCollection){
        if([m.bareJidStr isEqualToString:bare]){
            target = m;
            break;
        }
    }
    
    if(target)
        target.tag = 0;
}

-(void)updateRecentChatWithMessage:(XMPPMessageArchiving_Message_CoreDataObject *)message counted:(BOOL)count{
    NSString *mainKey = [NSString stringWithFormat:@"%d", GroupTypeChats];
    NSMutableDictionary *parent = [tableData valueForKey:mainKey];
    NSMutableArray *mainCollection = [parent valueForKey:@"content"];
    
    id toDelete = nil;
    for(XMPPMessageArchiving_Message_CoreDataObject *m in mainCollection){
        if([m.bareJidStr isEqualToString:message.bareJidStr]){
            toDelete = m;
            break;
        }
    }
    
    if(toDelete)
        [mainCollection removeObject:toDelete];
    
    if(count)
        message.tag = ((XMPPMessageArchiving_Message_CoreDataObject *)toDelete).tag + 1;
    
    [mainCollection insertObject:message atIndex:0];
    
    [parent setValue:mainCollection forKey:@"content"];
    [tableData setValue:parent forKey:mainKey];
    [tableView reloadData];
}

-(NSString *)parseEmoticons:(NSString *)str{
    for(NSDictionary *dict in emoticonsData){
        NSString *plain = [dict valueForKey:kTableFieldPlain];
        NSString *replace = [dict valueForKey:kTableFieldUnicode];
        
        str = [str stringByReplacingOccurrencesOfString:plain withString:replace];
    }
    
    return str;
}

#pragma mark - XMPPHandler delegate
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeRoster){
        NSMutableArray *rosterData = [info valueForKey:@"info"];
        
        // WCL - Modify 2014/2/19 - No.30, 31
        NSMutableDictionary *content = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"opened", rosterData, @"content", nil];
        [tableData setValue:content forKey:[NSString stringWithFormat:@"%d", GroupTypeFriends]];
        
        NSMutableDictionary *contentChats = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"opened", [NSMutableArray array], @"content", nil];
        [tableData setValue:contentChats forKey:[NSString stringWithFormat:@"%d", GroupTypeChats]];
        
        NSMutableArray *addToContact = [NSMutableArray array];
        for (XMPPUserCoreDataStorageObject *user in rosterData) {
            
            if(([user.subscription isEqualToString:@"from"] || [user.subscription isEqualToString:@"none"]) && [user.ask isEqualToString:@"subscribe"]) // Approval pending...
                continue;
            
            if ([user.subscription isEqualToString:@"to"])  // block
                continue;
            
            [addToContact addObject:user];
        }
        
        for(XMPPUserCoreDataStorageObject *user in rosterData){
            if(([user.subscription isEqualToString:@"from"] || [user.subscription isEqualToString:@"none"]) && [user.ask isEqualToString:@"subscribe"]) // Approval pending...
                continue;
            
            if ([user.subscription isEqualToString:@"to"])  // block
                continue;
            
            XMPPMessageArchiving_Message_CoreDataObject *message = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getLastMessageWithJid:user.jid streamJid:[SMXMPPHandler XMPPHandler].myJID];
            if(message){
                [self updateRecentChatWithMessage:message counted:NO];
            }
        }

        self.tempFriendsData = addToContact;
        [tableView reloadData];
        searchField.text = @"";
        // WCL - Modify 2014/2/19 - No.30, 31

    }else if(type == XMPPHandlerExecuteTypeAvatar){
        NSDictionary *dict = [info valueForKey:@"info"];
        UIImage *photo = [dict valueForKey:@"photo"];
        NSString *jid = [dict valueForKey:@"jid"];
        
        NSDictionary *sectionData = [tableData valueForKey:[NSString stringWithFormat:@"%d", GroupTypeFriends]];
        XMPPUserCoreDataStorageObject *obj = nil;
        for(XMPPUserCoreDataStorageObject *user in [sectionData valueForKey:@"content"]){
            if([user.jid.bare isEqualToString:jid]){
                obj = user;
            }
        }
        obj.photo = photo;
        
        [tableView reloadData];
    }else if(type == XMPPHandlerExecuteTypevCard){
        NSDictionary *dict = [info valueForKey:@"info"];
        NSString *jid = [dict valueForKey:@"jid"];
        if([jid isEqualToString:[SMXMPPHandler XMPPHandler].myJID.bare]){
            [self fetchMyRoomAndGroup];
        }
    }else if(type == XMPPHandlerExecuteTypeChat){
        XMPPMessage *message = [info valueForKey:@"info"];
        
        if(message.isGroupMessage){
        }else{
            if(message.isChatMessageWithBody){
                XMPPJID *friend = message.to;
                if([friend.bare isEqualToString:[SMXMPPHandler XMPPHandler].myJID.bare])
                    friend = message.from;
                
                XMPPMessageArchiving_Message_CoreDataObject *_message = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getLastMessageWithJid:friend streamJid:[SMXMPPHandler XMPPHandler].myJID];
                if(_message){
                    [self updateRecentChatWithMessage:_message counted:YES];
                }
            }else if(message.isAttentionMessage || message.isAttentionMessage2){
                NSMutableDictionary *toDelete = nil;
                for(NSMutableDictionary *dict in powedCell){
                    NSString *str = [dict valueForKey:@"name"];
                    if([str isEqualToString:message.from.bare]){
                        toDelete = dict;
                        break;
                    }
                }
                
                if(toDelete)
                   [powedCell removeObject:toDelete];
                
                [powedCell addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:message.from.bare, @"name", [NSNumber numberWithInt:5], @"count", nil]];
                
                [self startPowTimer];
            }else if(message.hasReceiptResponse){
                XMPPMessageArchiving_Message_CoreDataObject *m = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getMessageWithID:message.receiptResponseID];
                XMPPMessage *msg = m.message;
                msg.delivered = YES;
                m.messageStr = [NSString stringWithFormat:@"%@", msg];
                
                [[XMPPMessageArchivingCoreDataStorage sharedInstance] insertMessage:m];
                [tableView reloadData];
            }
        }
    }else if(type == XMPPHandlerExecuteTypeReceiveStatus){
//        [tableView reloadData];
    }
}

-(void)fetchMyRoomAndGroup{
    XMPPvCardTemp *vCard = [[SMXMPPHandler XMPPHandler] myvCardTemp];
    NSString *desc = vCard.description;
    
    NSDictionary *root = [desc JSONValue];
    NSArray *groups = [root valueForKey:kvCardDesGroupList];
    NSArray *rooms = [root valueForKey:kvCardDesRoomList];
    
    NSMutableDictionary *contentGroups = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"opened", groups, @"content", nil];
    [tableData setValue:contentGroups forKey:[NSString stringWithFormat:@"%d", GroupTypeGroups]];
    
    NSMutableDictionary *contentRooms = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"opened", rooms, @"content", nil];
    [tableData setValue:contentRooms forKey:[NSString stringWithFormat:@"%d", GroupTypeRooms]];
    
    [tableView reloadData];
}

-(void)startPowTimer{
    if(powTimer == nil){
        powTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(powBlink) userInfo:nil repeats:YES];
    }
}

static BOOL blink = YES;
-(void)powBlink{
    if(powedCell.count < 1){
        [powTimer invalidate];
        powTimer = nil;
    }
    blink = !blink;
    
    NSDictionary *dict = [tableData valueForKey:[NSString stringWithFormat:@"%d", GroupTypeChats]];
    NSMutableArray *content = [dict valueForKey:@"content"];
    
    NSInteger t = 0;
    for (int i=0; i<[content count]; i++) {
        SMRecentChatCell *cell = (SMRecentChatCell *) [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:t++ inSection:GroupTypeChats]];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    if(!blink)return;
    
    NSMutableArray *toDelete = [NSMutableArray array];
    
    for(NSMutableDictionary *dict in powedCell){
        NSInteger index = 0;
        NSString *bare = [dict valueForKey:@"name"];
        for(XMPPMessageArchiving_Message_CoreDataObject *obj in content){
            if([obj.bareJid.bare isEqualToString:bare]){
                SMRecentChatCell *cell = (SMRecentChatCell *) [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:GroupTypeChats]];
                cell.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.35];                break;
            }
            index++;
        }
        
        NSInteger count = [[dict valueForKey:@"count"] integerValue] - 1;
        [dict setObject:[NSNumber numberWithInt:(int)count] forKey:@"count"];
        
        if(count <= 0)
           [toDelete addObject:dict];
    }
    
    [powedCell removeObjectsInArray:toDelete];
}

#pragma mark - data source dan delegate tableView
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 25.;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = indexPath.section;
    NSString *key = [NSString stringWithFormat:@"%d", (int)section];
    NSMutableDictionary *dict = [tableData valueForKey:key];
    BOOL val = [[dict valueForKey:@"opened"] boolValue];
    
    if(!val)
        return 0.;
    
    return 45;
}

-(UIView *)tableView:(UITableView *)_tableView viewForHeaderInSection:(NSInteger)section{
    SMHeaderContactView *header = nil;

    if(!header){
        NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"SMHeaderContactView" owner:self options:nil];
        
        for(id one in arr){
            if([one isKindOfClass:[SMHeaderContactView class]]){
                header = one;
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerDidTapped:)];
                header.userInteractionEnabled = YES;
                [header addGestureRecognizer:tap];
                [tap release];
            }
        }
    }

    header.tag = section+1000;
    header.arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
    switch (section) {
        case GroupTypeChats:{
            header.bgView.backgroundColor = [UIColor colorWithRed:240/255. green:210/255. blue:80/255. alpha:1.];
            NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
            NSDictionary *dict = [tableData objectForKey:key];
            NSArray *array = [dict valueForKey:@"content"];
            header.titleLabel.text = [NSString stringWithFormat:@"Chats (%lu)", (unsigned long)array.count];
        }
            break;
        case GroupTypeFriends:{
            header.bgView.backgroundColor = [UIColor colorWithRed:234/255. green:125/255. blue:96/255. alpha:1.];
            header.titleLabel.text = [NSString stringWithFormat:@"Friends (%lu)", (unsigned long)self.tempFriendsData.count];
        }
            break;
        case GroupTypeGroups:{
            header.bgView.backgroundColor = [UIColor colorWithRed:9/255. green:198/255. blue:178/255. alpha:1.];
            NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
            NSDictionary *dict = [tableData objectForKey:key];
            NSArray *array = [dict valueForKey:@"content"];
            header.titleLabel.text = [NSString stringWithFormat:@"Groups (%lu)", (unsigned long)array.count];
        }
            break;
        case GroupTypeRooms:{
            header.bgView.backgroundColor = [UIColor colorWithRed:20/255. green:201/255. blue:218/255. alpha:1.];
            NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
            NSDictionary *dict = [tableData objectForKey:key];
            NSArray *array = [dict valueForKey:@"content"];
            header.titleLabel.text = [NSString stringWithFormat:@"Rooms (%lu)", (unsigned long)array.count];
        }
            break;
    }
    
    return header;
}

-(void)headerDidTapped:(UITapGestureRecognizer *)sender{
    NSInteger section = sender.view.tag;
    NSString *key = [NSString stringWithFormat:@"%d", (int)section-1000];
    NSMutableDictionary *dict = [tableData valueForKey:key];
    BOOL val = ![[dict valueForKey:@"opened"] boolValue];
    [dict setValue:[NSNumber numberWithBool:val] forKey:@"opened"];
    
    SMHeaderContactView *header = (SMHeaderContactView *)[tableView viewWithTag:section];
    if(val){
        header.arrowImage.transform = CGAffineTransformMakeRotation(M_PI);
    }else{
        header.arrowImage.transform = CGAffineTransformIdentity;
    }
    
    [tableView beginUpdates];
    [tableView endUpdates];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == GroupTypeFriends){
        return self.tempFriendsData.count;
    }
    
    NSString *key = [NSString stringWithFormat:@"%ld", (long)section];
    NSArray *arr = [[tableData valueForKey:key] valueForKey:@"content"];
    return arr.count;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0){
        SMRecentChatCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"SMRecentChatCell"];
        if(!cell){
            NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"SMRecentChatCell" owner:self options:nil];
            
            for(id one in arr){
                if([one isKindOfClass:[SMRecentChatCell class]]){
                    cell = one;
                }
            }
            
            UIView *bgSelected = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
            cell.selectedBackgroundView = bgSelected;
            [bgSelected release];
        }
        
        SMHeaderContactView *header  = (SMHeaderContactView *)[self tableView:tableView viewForHeaderInSection:indexPath.section];
        UIColor *color = header.bgView.backgroundColor;
        
        NSString *mainKey = [NSString stringWithFormat:@"%ld", (long)indexPath.section];
        NSArray *array = [[tableData objectForKey:mainKey] valueForKey:@"content"];
        XMPPMessageArchiving_Message_CoreDataObject *message = [array objectAtIndex:indexPath.row];
        
        if(message.message.isBroadcastMessage){
            NSDictionary *dict = message.message.parsedMessage;
            cell.recentMessage.textColor = [UIColor redColor];
            cell.recentMessage.text = [dict valueForKey:@"message"];
        }else if(message.message.isContactMessage){
            NSDictionary *dict = message.message.parsedMessage;
            cell.recentMessage.textColor = [UIColor blueColor];
            cell.recentMessage.text = [NSString stringWithFormat:@"\xE2\x98\x8E %@'s Contact", [dict valueForKey:@"name"]];
        }else if(message.message.isImageMessage){
            cell.recentMessage.textColor = [UIColor blackColor];
            if(message.message.isFileMessage){
                cell.recentMessage.text = @":: file ::";
            }else
                cell.recentMessage.text = [NSString stringWithFormat:@":: %@ ::",message.message.typeStr];
        }else if(message.message.isAttentionMessage || message.message.isAttentionMessage2){
            cell.recentMessage.textColor = [UIColor blueColor];
            cell.recentMessage.text = @":: POW ::";
        }else if(message.message.isLocationMessage){
            cell.recentMessage.textColor = [UIColor blueColor];
            if([message.message.to isEqualToJID:[SMXMPPHandler XMPPHandler].myJID options:XMPPJIDCompareBare])
                cell.recentMessage.text = @"\xF0\x9F\x93\x8D Friend's Location";
            else
                cell.recentMessage.text = @"\xF0\x9F\x93\x8D My Location";
        }else{
            cell.recentMessage.text = [self parseEmoticons:message.message.body];
            cell.recentMessage.textColor = [UIColor blackColor];
        }
        
        cell.selectedBackgroundView.backgroundColor = [color colorByChangingAlphaTo:0.4];
        
        if(message.tag > 10){
            cell.unreadNum.text = @"10+";
        }else{
            cell.unreadNum.text = [NSString stringWithFormat:@"%ld", (long)message.tag];
        }
        
        if(message.tag > 0){
            cell.recentMessageBG.hidden = NO;
            cell.unreadNum.hidden = NO;
        }else{
            cell.recentMessageBG.hidden = YES;
            cell.unreadNum.hidden = YES;
        }
        
        if(message.isOutgoing){
            cell.check.hidden = NO;
            CGRect frame = cell.recentMessage.frame;
            frame.origin.x = cell.check.frame.size.width + cell.check.frame.origin.x+3;
            cell.recentMessage.frame = frame;
            cell.check.highlighted = message.message.isDelivered;
        }else{
            cell.check.hidden = YES;
            CGRect frame = cell.recentMessage.frame;
            frame.origin.x = cell.check.frame.origin.x;
            cell.recentMessage.frame = frame;
        }
        
        NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
        [format setDateFormat:@"HH:mm"];
        cell.time.text = [format stringFromDate:message.timestamp];
        
        NSString *key = [NSString stringWithFormat:@"%d", GroupTypeFriends];
        NSArray *users = [[tableData objectForKey:key] valueForKey:@"content"];
        XMPPUserCoreDataStorageObject *user = nil;
        for(XMPPUserCoreDataStorageObject *one in users){
            if([one.jid.bare isEqualToString:message.bareJidStr]){
                user = one;
                break;
            }
        }
        
        cell.avatar.image = user.photo;
        
        XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:user.jid];
        
        if(temp.givenName.length){
            if(temp.middleName.length){
                cell.name.text = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
            }else{
                cell.name.text = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
            }
        }else if(user.nickname.length)
            cell.name.text = [NSString stringWithFormat:@"%@", user.nickname];
        else
            cell.name.text = user.jid.user;
        
        return cell;
    }else if(indexPath.section == 1){
        SMFriendsCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"SMFriendsCell"];
        if(!cell){
            NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"SMFriendsCell" owner:self options:nil];
            
            for(id one in arr){
                if([one isKindOfClass:[SMFriendsCell class]]){
                    cell = one;
                }
            }
            
            UIView *bgSelected = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
            cell.selectedBackgroundView = bgSelected;
            [bgSelected release];
        }
        
        SMHeaderContactView *header  = (SMHeaderContactView *)[self tableView:tableView viewForHeaderInSection:indexPath.section];
        UIColor *color = header.bgView.backgroundColor;
        
        XMPPUserCoreDataStorageObject *obj = [self.tempFriendsData objectAtIndex:indexPath.row];
        
        XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:obj.jid];
        
        if(temp.givenName.length){
            if(temp.middleName.length){
                cell.name.text = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
            }else{
                cell.name.text = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
            }
        }else if(obj.nickname.length)
            cell.name.text = [NSString stringWithFormat:@"%@", obj.nickname];
        else
            cell.name.text = obj.jid.user;
        
        cell.avatar.image = obj.photo;
        
        NSArray *arr = [obj.resources allObjects];
        XMPPResourceCoreDataStorageObject *resource = [arr lastObject];
        cell.status.text = resource.status;
        
        cell.selectedBackgroundView.backgroundColor = [color colorByChangingAlphaTo:0.4];
        
        return cell;
    }else if(indexPath.section == 2 || indexPath.section == 3){
        SMFriendsCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"SMFriendsCell"];
        if(!cell){
            NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"SMFriendsCell" owner:self options:nil];
            
            for(id one in arr){
                if([one isKindOfClass:[SMFriendsCell class]]){
                    cell = one;
                }
            }
            
            UIView *bgSelected = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 45)];
            cell.selectedBackgroundView = bgSelected;
            [bgSelected release];
        }
        
        SMHeaderContactView *header  = (SMHeaderContactView *)[self tableView:tableView viewForHeaderInSection:indexPath.section];
        UIColor *color = header.bgView.backgroundColor;
        
        NSDictionary *root = [tableData valueForKey:[NSString stringWithFormat:@"%ld", (long)indexPath.section]];
        NSArray *array = [root valueForKey:@"content"];
        NSDictionary *data = [array objectAtIndex:indexPath.row];
        
        cell.name.text = [[data valueForKey:kvCardDesTitle] uppercaseString];
        cell.avatar.image = [UIImage imageWithData:[NSData dataFromBase64String:[data valueForKey:kvCardDesThumb]]];
        cell.status.text = @"";
        
        cell.selectedBackgroundView.backgroundColor = [color colorByChangingAlphaTo:0.4];
        
        return cell;
    }
    
    return nil;
}

-(void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self hideKeyboard:nil];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [NSString stringWithFormat:@"%ld", (long)indexPath.section];
    NSArray *array = [[tableData objectForKey:key] valueForKey:@"content"];
    
    if(indexPath.section > 1){
        NSDictionary *dict = [array objectAtIndex:indexPath.row];
        NSString *jidStr = [dict valueForKey:kvCardDesJid];
        [[SMXMPPHandler XMPPHandler] createGroup:jidStr];
        return;
    }
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    if(delegate.mainViewController.leftControllerIsOpen || delegate.mainViewController.rightControllerIsOpen)
        return;
    
    if(indexPath.section == GroupTypeFriends)
        array = self.tempFriendsData;
    
    XMPPJID *destJID = nil;
    
    if(indexPath.section == 0){
        XMPPMessageArchiving_Message_CoreDataObject *obj = [array objectAtIndex:indexPath.row];
        destJID = obj.bareJid;
    }else if(indexPath.section == 1){
        XMPPUserCoreDataStorageObject *obj = [array objectAtIndex:indexPath.row];
        destJID = obj.jid;
    }
    
    XMPPUserCoreDataStorageObject *user = [[XMPPRosterCoreDataStorage sharedInstance] userForJID:destJID xmppStream:[SMXMPPHandler XMPPHandler].stream];
    XMPPResourceCoreDataStorageObject *r = [[user.resources allObjects] lastObject];
    NSString *jidFull = r.jidStr;
    
    BOOL online = NO;
    if(jidFull){
        destJID = [XMPPJID jidWithString:jidFull];
        online = YES;
    }
    
    SMChatPage *chat = [[SMChatPage alloc] init];
    chat.withJID = [[destJID copy] autorelease];
    chat.myJID = [[[SMXMPPHandler XMPPHandler].myJID copy] autorelease];
    chat.friendIsOnline = online;
    if(currentChatFriendsBare){
        [currentChatFriendsBare release];
        currentChatFriendsBare = nil;
    }
    currentChatFriendsBare = [destJID.bare copy];
    [self.navigationController pushViewController:chat animated:YES];
    [chat release];
}

#pragma mark - delegate TextField
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(result.length > 0){
        NSString *key = [NSString stringWithFormat:@"%d", GroupTypeFriends];
        NSArray *array = [[tableData objectForKey:key] valueForKey:@"content"];
        NSMutableArray *newArray = [NSMutableArray array];
        for(XMPPUserCoreDataStorageObject *obj in array){
            XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:obj.jid];
            
            NSString *displayName = @"";
            
            if(temp.givenName.length){
                if(temp.middleName.length){
                    displayName = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
                }else{
                    displayName = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
                }
            }else if(obj.nickname.length)
                displayName = [NSString stringWithFormat:@"%@", obj.nickname];
            else
                displayName = obj.jid.user;
            
            if([[displayName lowercaseString] rangeOfString:[result lowercaseString]].length > 0){
                [newArray addObject:obj];
            }
        }
        self.tempFriendsData = newArray;
        
        for(int sec=0; sec<4; sec++){
            if(sec == GroupTypeFriends)continue;
            NSString *key = [NSString stringWithFormat:@"%d", sec];
            NSMutableDictionary *dict = [tableData valueForKey:key];
            [dict setValue:[NSNumber numberWithBool:NO] forKey:@"opened"];
        }
    }else{
        NSString *key = [NSString stringWithFormat:@"%d", GroupTypeFriends];
        self.tempFriendsData = [[tableData objectForKey:key] valueForKey:@"content"];
    }
    
    [tableView reloadData];
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField{
    NSString *key = [NSString stringWithFormat:@"%d", GroupTypeFriends];
    self.tempFriendsData = [[tableData objectForKey:key] valueForKey:@"content"];
    [tableView reloadData];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    searchField.text = @"";
    [textField resignFirstResponder];
    NSString *key = [NSString stringWithFormat:@"%d", GroupTypeFriends];
    self.tempFriendsData = [[tableData objectForKey:key] valueForKey:@"content"];
    [tableView reloadData];
    return YES;
}

@end
