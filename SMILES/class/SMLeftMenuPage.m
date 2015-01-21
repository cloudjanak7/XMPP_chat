//
//  SMLeftMenuPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMLeftMenuPage.h"
#import "SMXMPPHandler.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMContactListPage.h"
#import "SMSettingPage.h"
#import "SMAddFriendPage.h"
#import "XMPPvCardTemp.h"
#import "SMFriendRequestPage.h"
#import "SMMyUserProfile.h"
#import "EGOImageView.h"
#import "SMBlockedPage.h"
#import "SMPopupPage.h"
#import "SMPopupPage.h"
#import <MessageUI/MessageUI.h>
#import "SMFriendsUpdatePage.h"
#import "SMRoomListPage.h"
#import "SMPopupPage.h"
#import "XMPPRoom.h"
#import "SMChatPage.h"
#import "SMBroadcastMessagePage.h"
#import "ASIFormDataRequest.h"
#import "SMPersistentObject.h"
#import "SMVisitorPage.h"
#import "SMNotificationPage.h"
#import "SMProfilePage.h"
#import "XMPPvCardTemp.h"

@interface SMLeftMenuPage () <UITableViewDataSource, UITableViewDelegate, SMPopupPageDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>{
    IBOutlet UITableView *table;
    IBOutlet EGOImageView *foto;
    IBOutlet UILabel *name;
    IBOutlet UILabel *status;
    
    NSArray *section0label;
    NSArray *section1label;
    NSMutableArray *requestArray;
    NSMutableArray *myRequestArray;
    NSMutableArray *blockedFriends;
    NSMutableArray *roomsData;
    NSInteger visitorNum;
}

-(IBAction)myProfile:(id)sender;

@end

@implementation SMLeftMenuPage

@synthesize notificationInfo;

- (void)dealloc
{
    [section0label release];
    [section1label release];
    [requestArray release];
    [myRequestArray release];
    [roomsData release];
    [notificationInfo release];
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
    requestArray = [[NSMutableArray alloc] init];
    myRequestArray = [[NSMutableArray alloc] init];
    blockedFriends = [[NSMutableArray alloc] init];
    roomsData = [[NSMutableArray alloc] init];
    
    table.backgroundColor = [UIColor colorWithRed:63/255. green:69/255. blue:69/255. alpha:1.];
    
    section0label = [[NSArray arrayWithObjects:@"Home", @"Add Friend / Group", @"Friend Request", @"Blocked Friends", nil] retain];
    section1label = [[NSArray arrayWithObjects:@"Friends Update", @"Visitors", @"Notifications", @"Room", @"Broadcast", @"Setting", @"Invite", @"Broadcast To All", nil] retain];
    
    [table reloadData];
    
    XMPPUserCoreDataStorageObject *myUser = [[SMXMPPHandler XMPPHandler] myUser];
    foto.image = myUser.photo;
    if(myUser.displayName)
        name.text = myUser.displayName;
    
    [self reloadTableView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self reloadTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - data source dan delegate tableView
-(void)reloadTableView{
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    foto.imageURL = [NSURL URLWithString:profile.avatarThumb];
    
    status.text = @"Set status on setting";
    name.text = @"Set display name on setting";
    
    if(profile.status.length > 0)
        status.text = profile.status;
    
    if(profile.fullname.length > 0)
        name.text = profile.fullname;
    
    [[SMPersistentObject sharedObject] getVisitors:20];
    visitorNum = [[SMPersistentObject sharedObject] getUnviewedVisitorNum];
    
    [table reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section==1)
        return 28.;
    
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 42.;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0){
        return section0label.count;
    }
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    
    if(profile.isAdmin)
        return section1label.count;
    
    return section1label.count-1;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 2.;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(section==1){
        UIView *header = nil;
        
        if(!header){
            header = [[[UIView alloc] init] autorelease];
            header.frame = CGRectMake(0, 0, 320, 28.);
            UIView *bg = [[UIView alloc] initWithFrame:header.frame];
            bg.backgroundColor = [UIColor blackColor];
            [header addSubview:bg];
            [bg release];
            
            
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(30., 0, 320, 28.)];
            lbl.text = @"Connection";
            lbl.textColor = [UIColor whiteColor];
            lbl.shadowColor = [UIColor darkGrayColor];
            lbl.shadowOffset = CGSizeMake(0, 1);
            lbl.font = [UIFont boldSystemFontOfSize:15.];
            lbl.backgroundColor = [UIColor clearColor];
            [header addSubview:lbl];
            [lbl release];
        }
        
        return header;
    }
    
    return nil;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"MenuLeftCell";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        
        UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 42.)];
        bg.backgroundColor = [UIColor colorWithRed:63/255. green:69/255. blue:69/255. alpha:1.];
        cell.backgroundView = bg;
        [bg release];
        
        UIView *bgFocus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 42.)];
        bgFocus.backgroundColor = [UIColor colorWithRed:63/255. green:69/255. blue:69/255. alpha:1.];
        cell.selectedBackgroundView = bgFocus;
        
        UIImage *box = [UIImage imageNamed:@"leftcell-box-focus.png"];
        UIImageView *boxView = [[UIImageView alloc] initWithImage:box];
        boxView.frame = CGRectMake(0, (42-29)*0.5, 4, 29.);
        [bgFocus addSubview:boxView];
        [boxView release];
        [bgFocus release];
        
        cell.textLabel.font = [UIFont systemFontOfSize:13.];
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.textLabel.shadowColor = [UIColor darkGrayColor];
        cell.textLabel.shadowOffset = CGSizeMake(0, 1);
        cell.textLabel.backgroundColor = [UIColor clearColor];
        
        UIImage *sparatorImage = [UIImage imageNamed:@"leftcell-sparator.png"];
        UIImageView *sparator = [[UIImageView alloc] initWithImage:sparatorImage];
        sparator.frame = CGRectMake(0, 40, 320, 2.);
        [cell addSubview:sparator];
        [sparator release];
        
        UIImage *arrowImage = [UIImage imageNamed:@"leftcell-arrow.png"];
        UIImageView *arrow = [[UIImageView alloc] initWithImage:arrowImage];
        arrow.frame = CGRectMake(240, 0.5*(42-12), 7, 12);
        arrow.tag = 1;
        [cell addSubview:arrow];
        [arrow release];
        
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(125, 0, 100, 42.)];
        lbl.text = @"0";
        lbl.textAlignment = NSTextAlignmentRight;
        lbl.font = [UIFont systemFontOfSize:13.];
        lbl.textColor = [UIColor lightGrayColor];
        lbl.shadowColor = [UIColor darkGrayColor];
        lbl.shadowOffset = CGSizeMake(0, 1);
        lbl.backgroundColor = [UIColor clearColor];
        lbl.tag = 2;
        [cell addSubview:lbl];
        [lbl release];
    }
    
    UIImageView *arrow = (UIImageView *)[cell viewWithTag:1];
    UILabel *number = (UILabel *)[cell viewWithTag:2];
    
    NSInteger jumlah = 0;
    
    if(indexPath.section == 0){
        cell.textLabel.text = [section0label objectAtIndex:indexPath.row];
        if(indexPath.row == 2){
            jumlah = requestArray.count + myRequestArray.count;
        }else if(indexPath.row == 3){
            jumlah = blockedFriends.count;
        }
    }else{
        cell.textLabel.text = [section1label objectAtIndex:indexPath.row];
        if(indexPath.row == 0){
            jumlah = [[SMPersistentObject sharedObject] getUnviewedFriendUpdate];
        }else if(indexPath.row == 1){
            jumlah = visitorNum;
        }else if(indexPath.row == 3){
            jumlah = roomsData.count;
        }
    }
    
    if(jumlah > 0){
        if (arrow) {
            arrow.hidden = NO;
        }
        if (number) {
            number.hidden = NO;
            number.text = [NSString stringWithFormat:@"%ld", (long)jumlah];
        }
    }else{
        if (arrow) {
            arrow.hidden = YES;
        }
        if (number) {
            number.hidden = YES;
        }
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                delegate.mainViewController.centerController = delegate.contactListPage;
            }];
        }else if(indexPath.row == 1){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                delegate.mainViewController.centerController = [[[SMAddFriendPage alloc] init] autorelease];
            }];
        }else if(indexPath.row == 2){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMFriendRequestPage *newPage = [[[SMFriendRequestPage alloc] init] autorelease];
                newPage.requestData = requestArray;
                newPage.myRequestData = myRequestArray;
                delegate.mainViewController.centerController = newPage;
            }];
        }else if(indexPath.row == 3){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMBlockedPage *newPage = [[[SMBlockedPage alloc] init] autorelease];
                newPage.blockedData = blockedFriends;
                delegate.mainViewController.centerController = newPage;
            }];
        }
    }else{
        if(indexPath.row == 0){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMFriendsUpdatePage *newPage = [[[SMFriendsUpdatePage alloc] init] autorelease];
                delegate.mainViewController.centerController = newPage;
            }];
        }else if(indexPath.row == 1){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMVisitorPage *newPage = [[[SMVisitorPage alloc] init] autorelease];
                delegate.mainViewController.centerController = newPage;
            }];
        }else if(indexPath.row == 2){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMNotificationPage *newPage = [[[SMNotificationPage alloc] init] autorelease];
                newPage.mainScreenMode = YES;
                newPage.data = self.notificationInfo;
                delegate.mainViewController.centerController = newPage;
            }];
        }else if(indexPath.row == 3){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMRoomListPage *roomList = [[SMRoomListPage alloc] init];
                roomList.roomsData = roomsData;
                delegate.mainViewController.centerController = [roomList autorelease];
            }];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }else if(indexPath.row == 4){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMBroadcastMessagePage *broadcast = [[SMBroadcastMessagePage alloc] init];
                delegate.mainViewController.centerController = [broadcast autorelease];
            }];
        }else if(indexPath.row == 5){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                delegate.mainViewController.centerController = [[[SMSettingPage alloc] init] autorelease];
            }];
        }else if(indexPath.row == 6){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeInviteOther];
                popup.delegate = self;
                popup.tag = 1;
                [popup show];
            }];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }else if(indexPath.row == 7){
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeAdminBroadcast];
                popup.delegate = self;
                popup.tag = 3;
                [popup show];
            }];
        }
    }
}

#pragma mark - delegate xmpphandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeLogin){
        [requestArray removeAllObjects];
        [myRequestArray removeAllObjects];
        [table reloadData];
    }else if(type == XMPPHandlerExecuteTypeFriendRequest){
        XMPPJID *jid = [info valueForKey:@"jid"];
        XMPPvCardTemp *vcard = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:jid];
        if(vcard.photo.length > 0){
            UIImage *_foto = [UIImage imageWithData:vcard.photo];
            NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_foto, @"photo", jid.user, @"name", nil];
            [requestArray addObject:_dict];
        }else{
            [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:jid];
            NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:jid.user, @"name", nil];
            [requestArray addObject:_dict];
        }
        [table reloadData];
    }else if(type == XMPPHandlerExecuteTypeAvatar){
        NSDictionary *newInfo = [info valueForKey:@"info"];
        UIImage *_foto = [newInfo valueForKey:@"photo"];
        NSString *jid = [newInfo valueForKey:@"jid"];
        
        NSMutableDictionary *target = nil;
        for(NSMutableDictionary *dict in requestArray){
            NSString *_name = [dict valueForKey:@"name"];
            if([_name isEqualToString:jid]){
                target = dict;
            }
        }
        [target setValue:_foto forKey:@"photo"];
        
        for(NSMutableDictionary *dict in myRequestArray){
            NSString *_name = [dict valueForKey:@"name"];
            if([_name isEqualToString:jid]){
                target = dict;
            }
        }
        [target setValue:_foto forKey:@"photo"];
        
        [table reloadData];
        
    }else if(type == XMPPHandlerExecuteTypeRoster){
        NSArray *rosterData = [info valueForKey:@"info"];
        
        [myRequestArray removeAllObjects];
        [blockedFriends removeAllObjects];

        for(XMPPUserCoreDataStorageObject *user in rosterData){
            if([user.ask isEqualToString:@"subscribe"]){
                XMPPJID *jid = user.jid;
                XMPPvCardTemp *vcard = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:jid];
                if(vcard.photo){
                    UIImage *_foto = [UIImage imageWithData:vcard.photo];
                    NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_foto, @"photo", jid.user, @"name", nil];
                    [myRequestArray addObject:_dict];
                }else{
                    [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:jid];
                    NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:jid.user, @"name", nil];
                    [myRequestArray addObject:_dict];
                }
            }else if([user.subscription isEqualToString:@"to"]){
                XMPPJID *jid = user.jid;
                XMPPvCardTemp *vcard = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:jid];
                if (vcard.photo && vcard.photo.length > 0) {
                    UIImage *_foto = [UIImage imageWithData:vcard.photo];
                    NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_foto, @"photo", jid.user, @"name", nil];
                    [blockedFriends addObject:_dict];
                } else {
                    [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:jid];
                    NSDictionary *_dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:jid.user, @"name", nil];
                    [blockedFriends addObject:_dict];
                }
            }
        }
        [table reloadData];
    }else if(type == XMPPHandlerExecuteTypeDidDiscoverRoom){
        NSMutableArray *arr = [info valueForKey:@"info"];
        
        if(roomsData){
            [roomsData removeAllObjects];
        }
        [roomsData addObjectsFromArray:arr];
        [table reloadData];
        
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        SMRoomListPage *roomlist = (SMRoomListPage *) [delegate.viewController.viewControllers lastObject];
        if([roomlist isKindOfClass:[SMRoomListPage class]]){
            [roomlist reloadView];
        }
    }else if(type == XMPPHandlerExecuteTypeGroupReceiveInvitation){
        XMPPJID *jid = [info valueForKey:@"jid"];
        XMPPJID *from = [info valueForKey:@"from"];
        NSString *message = [info valueForKey:@"message"];
        NSString *adminName = [info valueForKey:@"adminusername"];
        BOOL onlyInviteAdmin = [[info valueForKey:@"onlyinviteadmin"] boolValue];
        
        [[SMPersistentObject sharedObject] addOnlyInviteAdmin:jid.user bare:jid.bare adminUser:adminName onlyInviteAdmin:onlyInviteAdmin];
        
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        
        if(delegate.mainViewController.leftControllerIsOpen){
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeInviteGroup];
                popup.delegate = self;
                popup.message = message;
                popup.tag = 2;
                popup.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:jid, @"jid", nil];
                [popup show];
            }];
        }else if(delegate.mainViewController.rightControllerIsOpen){
            [delegate.mainViewController closeRightViewBouncing:^(IIViewDeckController *controller) {
                SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeInviteGroup];
                popup.delegate = self;
                popup.message = message;
                popup.tag = 2;
                popup.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:jid, @"jid", nil];
                [popup show];
            }];
        }else{
            SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeInviteGroup];
            popup.delegate = self;
            popup.message = message;
            popup.tag = 2;
            popup.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:jid, @"jid", nil];
            [popup show];
        }
        
        [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:from];
    }else if(type == XMPPHandlerExecuteTypeGroupReady){
        XMPPRoom *room = [info valueForKey:@"sender"];
        
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        
        if(delegate.mainViewController.leftControllerIsOpen){
            [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
                SMChatPage *chat = [[[SMChatPage alloc] init] autorelease];
                chat.myJID = [SMXMPPHandler XMPPHandler].myJID;
                chat.withJID = room.roomJID;
                chat.groupChat = YES;
                chat.room = room;
                [self.navigationController pushViewController:chat animated:YES];
            }];
        }else if(delegate.mainViewController.rightControllerIsOpen){
            [delegate.mainViewController closeRightViewBouncing:^(IIViewDeckController *controller) {
                SMChatPage *chat = [[[SMChatPage alloc] init] autorelease];
                chat.myJID = [SMXMPPHandler XMPPHandler].myJID;
                chat.withJID = room.roomJID;
                chat.groupChat = YES;
                chat.room = room;
                [self.navigationController pushViewController:chat animated:YES];
            }];
        }else{
            SMChatPage *chat = [[[SMChatPage alloc] init] autorelease];
            chat.myJID = [SMXMPPHandler XMPPHandler].myJID;
            chat.withJID = room.roomJID;
            chat.groupChat = YES;
            chat.room = room;
            [self.navigationController pushViewController:chat animated:YES];
        }
        
        [[SMXMPPHandler XMPPHandler] addGroupName:room.roomJID.user withJID:room.roomJID andThumb:nil];
    }
}

#pragma mark - delegate popup
-(void)smpopupView:(SMPopupPage *)viewController didSelectItemAtIndex:(NSInteger)index info:(NSDictionary *)info{
    if(viewController.tag == 1){
        SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
        [profile load];
        NSString *user = profile.fullname;
        
        NSString *message = [NSString stringWithFormat:@"Hi Friend,\nI'm using SMILES app, you can download at http://smilesatme.com/download.\nSee you there.\n\n%@", user];
        
        if(index == 0){
            if([MFMessageComposeViewController canSendText]){
                MFMessageComposeViewController *smsComposer =
                [[MFMessageComposeViewController alloc] init];
                
                smsComposer.body = message;
                smsComposer.messageComposeDelegate = self;
                [smsComposer setTitle:@"SMILES"];
                
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
                {
                    UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
                    window.clipsToBounds = YES;
                    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
                    
                    window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
                    window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
                }

                [self presentViewController:smsComposer animated:YES completion:nil];
            }else{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sory, your device does not support SMS" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
        }else{
            MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
            emailComposer.mailComposeDelegate = self;
            [emailComposer setSubject:@"Fun Apps"];
            [emailComposer setTitle:@"SMILES"];
            [emailComposer setMailComposeDelegate:self];
            [emailComposer setMessageBody:message isHTML:NO];
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
            {
                UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
                window.clipsToBounds = YES;
                [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
                
                window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
                window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
            }

            [self presentViewController:emailComposer animated:YES completion:^{
                
            }];
        }
    }else if(viewController.tag == 2){
        if(index == 1){
            XMPPJID *jid = [viewController.userInfo valueForKey:@"jid"];
            [[SMXMPPHandler XMPPHandler] createGroup:jid.full];
        }
    }else if(viewController.tag == 3){
        NSString *message = [info valueForKey:@"message"];
        [[SMXMPPHandler XMPPHandler] sendAdminBroadcast:message];
    }
    
    [viewController release];
}

#pragma mark - delegate email dan message
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [controller dismissViewControllerAnimated:YES completion:nil];
    [controller release];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [controller dismissViewControllerAnimated:YES completion:nil];
    [controller release];
}

#pragma mark - Action
-(void)myProfile:(id)sender{
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    [delegate.mainViewController closeLeftViewBouncing:^(IIViewDeckController *controller) {
        SMProfilePage *profile = [[SMProfilePage alloc] init];
        profile.myusername = [SMXMPPHandler XMPPHandler].myJID.user;
        profile.username = profile.myusername;
        [self.navigationController pushViewController:profile animated:YES];
        [profile release];
    }];
}

@end
