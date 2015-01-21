//
//  SMChatPage.m
//  SMILES
//
//  Created by asepmoels on 7/8/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChatPage.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import "XMPPMessageArchiving_Message_CoreDataObject.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "SMChatCell.h"
#import "XMPPMessage+XEP_0085.h"
#import "XMPPMessage+XEP_0184.h"
#import "XMPPMessage+MyCustom.h"
#import "SMChatObjectsSubPage.h"
#import "XMPPvCardTemp.h"
#import "SMXMPPHandler.h"
#import "XMPPResourceCoreDataStorageObject.h"
#import "SMPersistentObject.h"
#import "EGOImageView.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "XMPPRoom.h"
#import "SMProfilePage.h"
#import "XMPPMessage+XEP_0224.h"
#import "SMChatSettingPage.h"
#import "SMMyUserProfile.h"
#import "NSData+Base64.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "JSON.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <QuickLook/QuickLook.h>
#import <sqlite3.h>
#import "SMContactSelectPage.h"
#import "SMNotificationPage.h"
#import "SMInviteToGroupPage.h"
#import "SMSoundRecorder.h"
#import "SMAppDelegate.h"
#import "SMReportPage.h"
#import "HPGrowingTextView.h"
#import "SMSoundPlayer.h"

#define kCellVerticalPadding    3.

@interface SMChatPage ()<SMXMPPHandlerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SMChatObjectsSubPagaDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ASIHTTPRequestDelegate, UIActionSheetDelegate, QLPreviewControllerDataSource, SMContactSelectPageDelegate, SMSoundRecorderDelegate, UIAlertViewDelegate, HPGrowingTextViewDelegate, UIAlertViewDelegate>{
    IBOutlet UIImageView *lightEffectImageView;
    IBOutlet UIImageView *msgBackgroundImageView;
    IBOutlet UIButton *sendMsgButton;
    IBOutlet HPGrowingTextView *messageField;
    IBOutlet UITableView *table;
    IBOutlet UIView *inputView;
    IBOutlet UILabel *friendName;
    IBOutlet UILabel *friendStatus;
    IBOutlet UIImageView *friendPhoto;
    IBOutlet UIButton *subChatButton;
    IBOutlet UIView *subMenuGroup;
    IBOutlet UIView *subMenuPrivate;
    IBOutlet UIButton *toggleMenuButton;
    IBOutlet UIImageView *bgImageView;
    IBOutlet UIProgressView *progressAlert;
    IBOutlet UIView *alertContainer;
    IBOutlet UILabel *alertLabel;
    IBOutlet UIButton *blockButton;
    
    SMChatObjectsSubPage *subChat;
    NSMutableArray *chatData;
    NSMutableArray *displayChatData;
    NSMutableArray *resendChatData;
    UIFont *chatFont;
    NSTimer *iddleTimer;
    ChatState myCurrentChatState;
    NSOperationQueue *queue;
    NSArray *emoticonsData;
    NSString *temporaryString;
    NSString *temporaryURL;
    NSMutableArray *notifChat;
    SMSoundRecorder *soundRecord;
    SMSoundPlayer *soundPlayer;
}

-(IBAction)sendMessage:(id)sender;
-(IBAction)back:(id)sender;
-(IBAction)subChatViewToggle:(id)sender;
-(IBAction)toggleSubMenu:(id)sender;
-(IBAction)pow:(id)sender;
-(IBAction)chatSetting:(id)sender;
-(IBAction)leaveGroup:(id)sender;
-(IBAction)notification:(id)sender;
-(IBAction)inviteFriend:(id)sender;
-(IBAction)blockUnBlock:(id)sender;

@end

@implementation SMChatPage

@synthesize withJID, myJID, groupChat, friendIsOnline, room;

- (void)dealloc
{
    [queue cancelAllOperations];
    [withJID release];
    [chatData release];
    [displayChatData release];
    [resendChatData release];
    [myJID release];
    [subChat release];
    [queue release];
    [room release];
    [emoticonsData release];
    [temporaryString release];
    [temporaryURL release];
    [notifChat release];
    [soundRecord release];
    [soundPlayer release];
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
    queue = [[NSOperationQueue alloc] init];
    notifChat = [[NSMutableArray alloc] init];
    emoticonsData = [[[SMPersistentObject sharedObject] emoticonsGrouped:NO] retain];
    
    subChat = [[SMChatObjectsSubPage alloc] init];
    CGRect subChatFrame = subChat.view.frame;
    subChatFrame.origin.y = self.view.bounds.size.height - subChatFrame.size.height - inputView.frame.size.height;
    subChat.view.frame = subChatFrame;
    subChat.view.hidden = YES;
    subChat.user = self.myJID.user;

    [self.view addSubview:subChat.view];
    subChat.delegate = self;
    
    chatData = [[NSMutableArray alloc] init];
    displayChatData = [[NSMutableArray alloc] init];
    resendChatData = [[NSMutableArray alloc] init];
    
    [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableView:didSelectRowAtIndexPath:)];
    [table addGestureRecognizer:tap];
    [tap release];
   
    XMPPMessageArchivingCoreDataStorage *messageStorage = [XMPPMessageArchivingCoreDataStorage sharedInstance];
    NSArray *arr = [messageStorage getMessageWithJid:withJID streamJid:myJID];
    
    for(XMPPMessageArchiving_Message_CoreDataObject *message in arr){
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:message.message, @"message", [NSNumber numberWithBool:message.isOutgoing], @"outgoing", message.timestamp, @"time", message.message, @"text", nil];

        if(!message.message.isDelivered && !message.isOutgoing){
            [[SMXMPPHandler XMPPHandler] confirmDeliveryForMessage:message.message];
        }
        
        [chatData addObject:dict];
    }
    
    NSMutableArray *resendMsg = [[SMPersistentObject sharedObject] fetchResendMessage:self.myJID.user receiver:self.withJID.user];
    for (NSMutableDictionary *dict in resendMsg) {
        [resendChatData addObject:dict];
    }
    
    displayChatData = [self convertDisplayChatData];
    
    if(!self.groupChat){
        XMPPUserCoreDataStorageObject *friend = [[SMXMPPHandler XMPPHandler] userWithJID:self.withJID];
        
        XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:friend.jid];
        
        if(temp.givenName.length)
            friendName.text = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
        else if(friend.nickname.length)
            friendName.text = [NSString stringWithFormat:@"%@", friend.nickname];
        else
            friendName.text = friend.jid.user;
        
        if(temp.photo)
        friendPhoto.image = [UIImage imageWithData:temp.photo];
        
        NSArray *arrfriend = [friend.resources allObjects];
        XMPPResourceCoreDataStorageObject *resource = [arrfriend lastObject];
        friendStatus.text = resource.status;
    }else{
        friendStatus.text = @"";
    }
    
    if(!self.groupChat){
        [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateActive toJID:withJID];
    }else{
        friendName.text = [NSString stringWithFormat:@"%@", [self.withJID.user uppercaseString]];
    }
    myCurrentChatState = ChatStateActive;
    
    //[[SMXMPPHandler XMPPHandler] sendFile:@"file.txt" data:[NSData data] mime:@"text/plain" to:self.withJID];
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [friendPhoto addGestureRecognizer:tap2];
    [tap2 release];
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    NSString *bgImgPath = [profile.chatBackgrounds valueForKey:self.withJID.bare];
    NSError *error;
    NSString *bgImgStr = [NSString stringWithContentsOfFile:bgImgPath encoding:NSUTF8StringEncoding error:&error];
    NSData *bgImgData = [NSData dataFromBase64String:bgImgStr];
    if(bgImgData.length > 0)
        bgImageView.image = [UIImage imageWithData:bgImgData];
    
    alertContainer.hidden = YES;
    
    [self reloadAvatar];
    
    soundRecord = [[SMSoundRecorder alloc] init];
    soundRecord.delegate = self;
    
    soundPlayer = [[SMSoundPlayer alloc] init];
    
    messageField.isScrollable = NO;
    messageField.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
    
	messageField.minNumberOfLines = 1;
	messageField.maxNumberOfLines = 5;
	messageField.returnKeyType = UIReturnKeyDefault; //just as an example
	messageField.delegate = self;
    messageField.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    messageField.backgroundColor = [UIColor clearColor];
    messageField.placeholder = @"message...";
    [self resizeInputView:(26.-messageField.frame.size.height) stretch:NO];
    
    UIImage *rawEntryBackground = [UIImage imageNamed:@"text-field-chat.png"];
    UIImage *entryBackground = [rawEntryBackground stretchableImageWithLeftCapWidth:rawEntryBackground.size.width/2 topCapHeight:rawEntryBackground.size.height/2];
    msgBackgroundImageView.image = entryBackground;
    msgBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
}

-(void)viewDidUnload{
    [super viewDidUnload];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:self.myJID.user];
    [profile load];
    chatFont = [[UIFont systemFontOfSize:profile.chatFontSize] retain];
    [table reloadData];
    
    [subChat reloadData];

    if (displayChatData.count > 0)
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    messageField.font = chatFont;
}

-(void)viewWillUnload{
    [super viewWillUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)imageTapped:(UITapGestureRecognizer *)gesture{
    if(!self.groupChat){
        SMProfilePage *profile = [[SMProfilePage alloc] init];
        profile.username = self.withJID.user;
        profile.myusername = self.myJID.user;
        [self.navigationController pushViewController:profile animated:YES];
        [profile release];
    }
}

-(void)sendMessage:(id)sender{
    if(messageField.text.length < 1)return;
    
    if (groupChat) {
        [self sendMessage1:YES blockedFriend:nil];
    } else {
        if (blockButton.selected) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"This user is blocked."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
            return;
        }
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendBlockList]];
        request.tag = 10;
        [request setPostValue:self.withJID.user forKey:@"username"];
        [request setPostValue:[NSNumber numberWithInt:0] forKey:@"page"];
        [request setPostValue:[NSNumber numberWithInt:100] forKey:@"limit"];
        request.delegate = self;
        [request startAsynchronous];
    }
}

- (void)sendMessage1:(BOOL)requestSuccess blockedFriend:(NSMutableArray *)blockedFriends {
    
    if (!requestSuccess) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Please check your network connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
        return;
    }
    
    if (blockedFriends != nil && (NSNull *)blockedFriends != [NSNull null]) {
        for (NSMutableDictionary *dict in blockedFriends) {
            // check whether your chater blocks you.
            if (dict) {
                NSString *strUserName = [dict objectForKey:@"username"];
                if (strUserName) {
                    if ([strUserName isEqualToString:self.myJID.user]) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                                        message:@"You cannot chat this user becase he blocked you."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil, nil];
                        [alert show];
                        [alert release];
                        return;
                    }
                }
            }
        }
    }
    
    SMAppDelegate* delegate = (SMAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (![delegate reachability])
    {  // if internet is inactive
        if (groupChat) {
            
        }
        else
        {
            // WCL - Add 2014/2/18 No.19
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"resendmessage", @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", messageField.text, @"text", self.myJID.user, @"sender", self.withJID.user, @"receiver", nil];
            int inserted_id = [[SMPersistentObject sharedObject] addResendMessage:dict];
            
            if (inserted_id > 0) {
                NSMutableDictionary *insertedDict = [[SMPersistentObject sharedObject] fetchResendMessageById:inserted_id];
                [resendChatData addObject:insertedDict];
                displayChatData = [self convertDisplayChatData];
                
                messageField.text = @"";
                [table reloadData];
                [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            
            return;
        }
    }
    
    if (groupChat) {
        XMPPMessage *_message = [self.room sendMessage:messageField.text];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", _message, @"text", nil];
        [chatData addObject:dict];
        displayChatData = [self convertDisplayChatData];
        [table reloadData];
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else {
        
        [[SMXMPPHandler XMPPHandler] sendMessage:messageField.text to:self.withJID];
        
        [self stopIddleTimer];
        [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateActive toJID:withJID];
        myCurrentChatState = ChatStateActive;
        
        [self sendWakeUp];
    }
    
    messageField.text = @"";
}

-(void)sendWakeUp{
    XMPPUserCoreDataStorageObject *me = [[SMXMPPHandler XMPPHandler] userWithJID:self.withJID];
    XMPPResourceCoreDataStorageObject *meRe = [[me.resources allObjects] lastObject];
    if(!meRe){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLWakeup]];
        [request setPostValue:self.myJID.user forKey:@"username"];
        [request setPostValue:self.withJID.user forKey:@"targetname"];
        [request startAsynchronous];
        [request setCompletionBlock:^{
            NSLog(@"nah ini reply wakeup %@", [request responseString]);
        }];
    }
}

-(void)stopIddleTimer{
    if(iddleTimer){
        [iddleTimer invalidate];
        iddleTimer = nil;
    }
}

-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGRect rect = [[userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = inputView.frame;
    frame.origin.y = self.view.frame.size.height - rect.size.height - frame.size.height;
    inputView.frame = frame;
    
    frame = table.frame;
    frame.size.height = inputView.frame.origin.y - frame.origin.y;
    table.frame = frame;
    
    CGRect subChatFrame = subChat.view.frame;
    subChatFrame.origin.y = self.view.bounds.size.height - subChatFrame.size.height - inputView.frame.size.height - rect.size.height;
    subChat.view.frame = subChatFrame;
    [UIView commitAnimations];
    
    if (displayChatData.count > 0)
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

-(void)showMostBottomCell{
    if (displayChatData.count > 0)
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

-(void)keyboardDidHide:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = inputView.frame;
    frame.origin.y = self.view.frame.size.height - frame.size.height;
    inputView.frame = frame;
    
    frame = table.frame;
    frame.size.height = inputView.frame.origin.y - frame.origin.y;
    table.frame = frame;
    
    CGRect subChatFrame = subChat.view.frame;
    subChatFrame.origin.y = self.view.bounds.size.height - subChatFrame.size.height - inputView.frame.size.height;
    subChat.view.frame = subChatFrame;
    [UIView commitAnimations];
}

-(void)back:(id)sender{
    [messageField resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
    [table removeGestureRecognizer:[table.gestureRecognizers objectAtIndex:0]];
    
    [self stopIddleTimer];
    [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateInactive toJID:withJID];
    myCurrentChatState = ChatStateInactive;
    
    [self.navigationController popViewControllerAnimated:YES];
    
    if(self.groupChat)
       [self.room leaveRoom];
}

-(void)subChatViewToggle:(UIButton *)sender{
    sender.selected = !sender.selected;
    subChat.view.hidden = !sender.selected;
}

-(void)toggleSubMenu:(UIButton *)sender{
    sender.selected = !sender.selected;
    UIView *newView = subMenuPrivate;
    
    if(self.groupChat)
        newView = subMenuGroup;
    
    if(sender.selected){
        newView.alpha = 0.;
        CGRect frame = newView.frame;
        frame.origin.y = -100;
        newView.frame = frame;
        [self.view insertSubview:newView aboveSubview:table];
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDuration:0.25];
        frame.origin.y = table.frame.origin.y;
        newView.frame = frame;
        newView.alpha = 1.;
        table.alpha = 0.5;
        bgImageView.alpha = 0.3;
        [UIView commitAnimations];
    }else{
        CGRect frame = newView.frame;
        frame.origin.y = -100;
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationDelegate:newView];
        [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
        newView.frame = frame;
        newView.alpha = 0.;
        table.alpha = 1.;
        bgImageView.alpha = 1.;
        [UIView commitAnimations];
    }
}

-(void)pow:(id)sender{
    if(self.groupChat){
        XMPPMessage *_message = [self.room sendMessage:@"4T3NT10NK03@"];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", _message, @"text", nil];
        [chatData addObject:dict];
        displayChatData = [self convertDisplayChatData];
        [table reloadData];
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }else{
        [[SMXMPPHandler XMPPHandler] pow:self.withJID];
        [self sendWakeUp];
    }
}

-(void)chatSetting:(id)sender{
    toggleMenuButton.selected = YES;
    [self toggleSubMenu:toggleMenuButton];
    
    SMChatSettingPage *setting = [[SMChatSettingPage alloc] init];
    setting.friendBare = self.withJID.bare;
    setting.backgroundToChange = bgImageView;
    setting.tableToRefresh = table;
    setting.chatDataToChange = chatData;
    [self.navigationController pushViewController:setting animated:YES];
    [setting release];
}

-(NSString *)parseEmoticons:(NSString *)str{
    for(NSDictionary *dict in emoticonsData){
        NSString *plain = [dict valueForKey:kTableFieldPlain];
        NSString *replace = [dict valueForKey:kTableFieldUnicode];
        
        str = [str stringByReplacingOccurrencesOfString:plain withString:replace];
    }
    
    return str;
}

-(void)attachmentTapped:(UITapGestureRecognizer *)tap{
    if(temporaryString){
        [temporaryString release];
        temporaryString = nil;
    }
    
    NSString *info = ((EGOImageView *)tap.view).additionInfo;
    if(info)
        temporaryString = [info retain];
    
    NSString *type = [[info JSONValue] valueForKey:@"type"];
    
    if([type isEqualToString:@"AUDIO"]){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:type delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Listen" otherButtonTitles:nil];
        sheet.tag = 0;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:type delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"View" otherButtonTitles:@"Save", nil];
        sheet.tag = 0;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }
}

-(void)locationTapped:(UITapGestureRecognizer *)tap{
    if(temporaryString){
        [temporaryString release];
        temporaryString = nil;
    }
    
    UIView *parent = [tap.view superview];
    EGOImageView *target = nil;
    
    for(id one in parent.subviews){
        if([one isKindOfClass:[EGOImageView class]]){
            target = (EGOImageView *)one;
            break;
        }
    }
    
    NSString *info = target.additionInfo;
    if(info)
        temporaryString = [info retain];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[[info JSONValue] valueForKey:@"type"] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"View On Map" otherButtonTitles:nil];
    sheet.tag = 1;
    [sheet showInView:self.view];
    sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
}

-(void)contactTapped:(UITapGestureRecognizer *)tap{
    if(temporaryString){
        [temporaryString release];
        temporaryString = nil;
    }
    
    UIView *parent = [tap.view superview];
    EGOImageView *target = nil;
    
    for(id one in parent.subviews){
        if([one isKindOfClass:[EGOImageView class]]){
            target = (EGOImageView *)one;
            break;
        }
    }
    
    NSString *info = target.additionInfo;
    if(info)
        temporaryString = [info retain];
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[[info JSONValue] valueForKey:@"type"] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"View" otherButtonTitles:@"Call", @"SMS", nil];
    sheet.tag = 2;
    [sheet showInView:self.view];
    sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
}

-(void)reloadAvatar{
    if(!self.groupChat)return;
    
    XMPPvCardTemp *vcard = [[SMXMPPHandler XMPPHandler] myvCardTemp];
    NSDictionary *root = [vcard.description JSONValue];
    NSArray *grup = [root valueForKey:kvCardDesGroupList];
    
    if([self.withJID.domain rangeOfString:@"room"].length > 0){
        grup = [root valueForKey:kvCardDesRoomList];
    }
    
    for(NSDictionary *dict in grup){
        NSString *jid = [dict valueForKey:kvCardDesJid];
        if([jid isEqualToString:self.withJID.bare]){
            NSData *imgData = [NSData dataFromBase64String:[dict valueForKey:kvCardDesThumb]];
            friendPhoto.image = [UIImage imageWithData:imgData];
            break;
        }
    }
}

-(void)leaveGroup:(id)sender{
    [self.room leaveRoom];
    [self.navigationController popViewControllerAnimated:YES];
    [[SMXMPPHandler XMPPHandler] removeGroupName:[friendName.text lowercaseString] withJID:self.room.roomJID];
    [[SMPersistentObject sharedObject] deleteOnlyInviteAdmin:self.room.roomJID.user bare:self.room.roomJID.bare];
}

-(void)notification:(id)sender{
    toggleMenuButton.selected = YES;
    [self toggleSubMenu:toggleMenuButton];
    
    SMNotificationPage *notif = [[SMNotificationPage alloc] init];
    notif.data = notifChat;
    [self.navigationController pushViewController:notif animated:YES];
    [notif release];
}

-(void)inviteFriend:(id)sender{
    
    NSDictionary *dict = [[SMPersistentObject sharedObject] fetchOnlyInviteAdmin:self.room.roomJID.user bare:self.room.roomJID.bare];
    if (dict && [[dict objectForKey:@"onlyinviteadmin"] boolValue]) { // if onlyInviteAdmin option is checked
        if (![[dict objectForKey:@"adminusername"] isEqualToString:[SMXMPPHandler XMPPHandler].myJID.user]) { // If you are not group creator
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Only the group creator can invite other members." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
    }
    
    toggleMenuButton.selected = YES;
    [self toggleSubMenu:toggleMenuButton];
    
    SMInviteToGroupPage *invite = [[SMInviteToGroupPage alloc] init];
    invite.room = self.room;
    [self.navigationController pushViewController:invite animated:YES];
    [invite release];
}

-(void)blockUnBlock:(UIButton *)sender{
    toggleMenuButton.selected = YES;
    [self toggleSubMenu:toggleMenuButton];
    
    sender.selected = !sender.selected;
    
    [[SMXMPPHandler XMPPHandler] blockFriend:self.withJID block:sender.selected];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"You cannot chat this user any more."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    alert.tag = 1;
    [alert show];
    [alert release];
}

- (IBAction)onReportBtnPressed:(id)sender {
    toggleMenuButton.selected = YES;
    [self toggleSubMenu:toggleMenuButton];
    
    SMReportPage *report = [[SMReportPage alloc] init];
    report.sSender = self.myJID.user;
    report.sSuspect = self.withJID.user;
    [self.navigationController pushViewController:report animated:YES];
    [report release];
}


#pragma mark - delegate XMMP Handler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeChat){
        XMPPMessage *message = [info valueForKey:@"info"];
        
        if([message.from.bare isEqualToString:self.withJID.bare]){
            NSString *msgType = [message attributeStringValueForName:@"type"];
            if([msgType isEqualToString:@"error"]){
                [[XMPPMessageArchivingCoreDataStorage sharedInstance] deleteMessageWithID:message.elementID];
                
                message = [XMPPMessage messageWithType:@"error" child:[DDXMLElement elementWithName:@"body" stringValue:@"You were disconnected from Group/Room because the Room/Group is too long idle. Please close and reopen this screen."]];
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:message, @"message", [NSNumber numberWithBool:NO], @"outgoing", [NSDate date], @"time", message, @"text", nil];
                [chatData addObject:dict];
                displayChatData = [self convertDisplayChatData];
                [table reloadData];
                [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }else if(message.isChatMessageWithBody || message.isAttentionMessage){
                if(message.isGroupMessage){
                    if(message.from.resource.length < 1){
                        NSDictionary *newObject = [NSDictionary dictionaryWithObjectsAndKeys:message.body, @"message", [NSDate date], @"timestamp", nil];
                        [notifChat insertObject:newObject atIndex:0];
                        return;
                    }
                    
                    if([message.from.resource isEqualToString:self.myJID.user]){
                        XMPPMessageArchiving_Message_CoreDataObject *m = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getMessageWithID:message.elementID];
                        XMPPMessage *msg = m.message;
                        msg.delivered = YES;
                        m.messageStr = [NSString stringWithFormat:@"%@", msg];
                        
                        [[XMPPMessageArchivingCoreDataStorage sharedInstance] insertMessage:m];
                        
                        NSMutableDictionary *target = nil;
                        int index_section = 0;
                        int index_row = 0;
                        BOOL bBreak = NO;
                        
                        for (int section=0; section<displayChatData.count; section++) {
                            NSMutableArray *subArray = [displayChatData objectAtIndex:section];
                            index_section = section;
                            
                            for (int row=0; row<subArray.count; row++) {
                                NSMutableDictionary *dict = [subArray objectAtIndex:row];
                                index_row = row;

                                if ([[dict valueForKey:@"text"] isKindOfClass:[XMPPMessage class]]) {
                                    XMPPMessage *msg = [dict valueForKey:@"text"];
                                    if([msg.elementID isEqualToString:message.elementID]){
                                        target =  dict;
                                        bBreak = YES;
                                        break;
                                    }
                                }
                            }
                            
                            if (bBreak) {
                                break;
                            }
                        }
                        
                        if(target){
                            [target setValue:msg forKey:@"text"];
                            [table reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index_row inSection:index_section]] withRowAnimation:UITableViewRowAnimationNone];
                        }
                        
                        return;
                    }
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:message, @"message", [NSNumber numberWithBool:NO], @"outgoing", [NSDate date], @"time", message, @"text", nil];
                [chatData addObject:dict];
                displayChatData = [self convertDisplayChatData];
                [table reloadData];
                [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
                
                if(message.hasReceiptRequest){
                    [[SMXMPPHandler XMPPHandler] confirmDeliveryForMessage:message];
                }
            }else{
                if(message.hasChatState){
                    if(message.isActiveChatState){
                        friendStatus.text = @"Active";
                    }else if(message.isComposingChatState){
                        friendStatus.text = @"Typing...";
                    }else if(message.isPausedChatState){
                        friendStatus.text = @"Waiting...";
                    }else if(message.isInactiveChatState){
                        friendStatus.text = @"Inactive";
                    }
                }else if(message.hasReceiptResponse){
                    XMPPMessageArchiving_Message_CoreDataObject *m = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getMessageWithID:message.receiptResponseID];
                    XMPPMessage *msg = m.message;
                    msg.delivered = YES;
                    m.messageStr = [NSString stringWithFormat:@"%@", msg];
                    
                    [[XMPPMessageArchivingCoreDataStorage sharedInstance] insertMessage:m];

                    NSMutableDictionary *target = nil;
                    int index_section = 0;
                    int index_row = 0;
                    BOOL bBreak = NO;
                    
                    for (int section=0; section<displayChatData.count; section++) {
                        NSMutableArray *subArray = [displayChatData objectAtIndex:section];
                        index_section = section;
                        
                        for (int row=0; row<subArray.count; row++) {
                            NSMutableDictionary *dict = [subArray objectAtIndex:row];
                            index_row = row;
                            
                            if ([[dict valueForKey:@"text"] isKindOfClass:[XMPPMessage class]]) {
                                XMPPMessage *msg = [dict valueForKey:@"text"];
                                if([msg.elementID isEqualToString:message.receiptResponseID]){
                                    target =  dict;
                                    bBreak = YES;
                                    break;
                                }
                            }
                        }
                        
                        if (bBreak) {
                            break;
                        }
                    }
                    
                    if(target){
                        [target setValue:msg forKey:@"text"];
                        [table reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index_row inSection:index_section]] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }else{
                
                }
            }
        }else if([message.to.bare isEqualToString:withJID.bare]){
            XMPPMessage *_message = [info valueForKey:@"info"];
            
            if(_message.isChatMessageWithBody || _message.isAttentionMessage){
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", _message, @"text", nil];
                [chatData addObject:dict];
                displayChatData = [self convertDisplayChatData];
                [table reloadData];
                [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    }else if(type == XMPPHandlerExecuteTypevCard){
        [self reloadAvatar];
    }else if(type == XMPPHandlerExecuteTypeRoomActivity){
        [notifChat insertObject:info atIndex:0];
    }
}

#pragma mark - data source dan delegate tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return displayChatData.count;   // count of date
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    // remove empty text item.
    NSMutableArray *array = [displayChatData objectAtIndex:section];
    for (NSDictionary *data in array) {
    
        if ([[data valueForKey:@"message"] isKindOfClass:[XMPPMessage class]] ) {
            XMPPMessage *message = [data valueForKey:@"message"];
            
            if (message) {
                NSString *messageStr = [self parseEmoticons:message.body];
                if (!messageStr || [messageStr isEqualToString:@""]) {
                    [array removeObject:data];
                }
            }
        }
    }
    
    return [[displayChatData objectAtIndex:section] count]; // count of chat list
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *data = [[displayChatData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSString *messageStr = @"";
    XMPPMessage *message = NULL;
    
    if ([[data valueForKey:@"message"] isKindOfClass:[XMPPMessage class]]) {
        message = [data valueForKey:@"message"];
        
        if(message.isBroadcastMessage){
            NSDictionary *dict = message.parsedMessage;
            messageStr = [dict valueForKey:@"message"];
        }else if(message.isContactMessage){
            NSDictionary *dict = message.parsedMessage;
            messageStr = [NSString stringWithFormat:@"\xE2\x98\x8E %@'s Contact", [dict valueForKey:@"name"]];
        }else if(message.isImageMessage){
            return 320.*2./5. + kCellVerticalPadding + 7 + kCellVerticalPadding;
        }else if(message.isAttentionMessage || message.isAttentionMessage2){
            return 320.*2./5. + kCellVerticalPadding + 7 + kCellVerticalPadding;
        }else if(message.isLocationMessage){
            if([message.to isEqualToJID:self.myJID options:XMPPJIDCompareBare]){
                NSString *user = message.from.user;
                
                if(message.isGroupMessage){
                    user = message.from.resource;
                }
                
                messageStr = [NSString stringWithFormat:@"\xF0\x9F\x93\x8D %@'s Location", user];
            }else{
                messageStr = @"\xF0\x9F\x93\x8D My Location";
            }
        }else{
            messageStr = message.body;
        }
    } else {
        // if resend message
        messageStr = [data valueForKey:@"text"];
    }

    messageStr = [self parseEmoticons:messageStr];
    CGSize textSize = CGSizeZero;
    
    if (message && message.isGroupMessage && message.from.resource.length > 0) {
        NSString *senderName = message.from.resource;
        CGSize senderNameSize = [senderName sizeWithFont:chatFont];
        textSize = [messageStr sizeWithFont:chatFont constrainedToSize:CGSizeMake(320*2./3-senderNameSize.width, 2000) lineBreakMode:NSLineBreakByWordWrapping];
    } else {
        textSize = [messageStr sizeWithFont:chatFont constrainedToSize:CGSizeMake(320*2./3, 2000) lineBreakMode:NSLineBreakByWordWrapping];
    }
    
    textSize.width += 3; textSize.height += 3;
    return textSize.height + 2*kCellVerticalPadding + 10;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"SMChatCell";
    
    SMChatCell *cell = (SMChatCell *)[_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"SMChatCell" owner:self options:nil];
        
        for(id one in array){
            if([one isKindOfClass:[SMChatCell class]]){
                cell = (SMChatCell *)one;
            }
        }
    }
    
    for(id one in cell.messageImage.gestureRecognizers)
        [cell.messageImage removeGestureRecognizer:one];
    for(id one in cell.messageBG.gestureRecognizers)
        [cell.messageBG removeGestureRecognizer:one];
    
    NSDictionary *data = [[displayChatData objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([[data valueForKey:@"message"] isKindOfClass:[XMPPMessage class]] ) {
        XMPPMessage *message = [data valueForKey:@"message"];
        
        NSString *messageStr = [self parseEmoticons:message.body];
        BOOL outgoing = [[data valueForKey:@"outgoing"] boolValue];
        NSDate *time = [data valueForKey:@"time"];
        
        NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
        [format setDateFormat:@"hh:mm a"];
        
        if([[message attributeStringValueForName:@"type"] isEqualToString:@"error"]){
            cell.message.font = chatFont;
            cell.message.text = messageStr;
            cell.message.textColor = [UIColor orangeColor];
        }else if(message.isBroadcastMessage){
            NSDictionary *dict = message.parsedMessage;
            cell.message.textColor = [UIColor redColor];
            cell.message.text = [dict valueForKey:@"message"];
            cell.message.font = chatFont;
        }else if(message.isContactMessage){
            NSDictionary *dict = message.parsedMessage;
            cell.message.font = chatFont;
            cell.message.textColor = [UIColor blueColor];
            cell.message.text = [NSString stringWithFormat:@"\xE2\x98\x8E %@'s Contact", [dict valueForKey:@"name"]];
            
            cell.messageBG.userInteractionEnabled = YES;
            UITapGestureRecognizer *thumbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contactTapped:)];
            [cell.messageBG addGestureRecognizer:thumbTap];
            cell.messageImage.additionInfo = [message.parsedMessage JSONRepresentation];
            
            [thumbTap release];
        }else if(message.isImageMessage){
            cell.message.text = @"";
            if(message.isFileMessage){
                NSDictionary *parsedDic = message.parsedMessage;
                NSString *thumbUrlStr = [parsedDic valueForKey:@"thumb"];
                cell.messageImage.imageURL = [NSURL URLWithString:thumbUrlStr];
                
                UITapGestureRecognizer *thumbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(attachmentTapped:)];
                [cell.messageImage addGestureRecognizer:thumbTap];
                cell.messageImage.userInteractionEnabled = YES;
                cell.messageImage.additionInfo = [parsedDic JSONRepresentation];
                
                [thumbTap release];
                
                if ([[parsedDic objectForKey:@"type"] isEqualToString:@"VIDEO"]) {
                    cell.videoPlayImgView.hidden = NO;
                } else {
                    cell.videoPlayImgView.hidden = YES;
                }
            }else{
                cell.messageImage.imageURL = [message imageURL];
            }
        }else if(message.isAttentionMessage || message.isAttentionMessage2){
            cell.messageImage.image = [UIImage imageNamed:@"POWERRR_ui.png"];
        }else if(message.isLocationMessage){
            cell.message.font = chatFont;
            cell.message.textColor = [UIColor blueColor];
            if([message.to isEqualToJID:self.myJID options:XMPPJIDCompareBare]){
                NSString *user = message.from.user;
                
                if(message.isGroupMessage){
                    user = message.from.resource;
                }
                
                cell.message.text = [NSString stringWithFormat:@"\xF0\x9F\x93\x8D %@'s Location", user];
            }else{
                cell.message.text = @"\xF0\x9F\x93\x8D My Location";
            }
            
            cell.messageBG.userInteractionEnabled = YES;
            UITapGestureRecognizer *thumbTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationTapped:)];
            [cell.messageBG addGestureRecognizer:thumbTap];
            cell.messageImage.additionInfo = [message.parsedMessage JSONRepresentation];
            
            [thumbTap release];
        }else{
            cell.message.font = chatFont;
            cell.message.text = messageStr;
            cell.message.textColor = [UIColor blackColor];
        }
        
        if(message.isGroupMessage && message.from.resource.length > 0) {
            cell.messagetimestamp.text = [NSString stringWithFormat:@"%@ | %@", message.from.resource, [format stringFromDate:time]];
        } else {
            cell.messagetimestamp.text = [format stringFromDate:time];
        }
        [cell.messagetimestamp sizeToFit];
        
        CGSize textSize = [cell.message.text sizeWithFont:chatFont constrainedToSize:CGSizeMake(320*2./3., 2000) lineBreakMode:NSLineBreakByWordWrapping];
        textSize.width += 3; textSize.height += 3;

        CGRect textOnlyFrame;
        CGRect bgFrame;
        CGRect videoPlayFrame;
        CGRect timestampContainerFrame;
        CGRect timestampLabelFrame = cell.messagetimestamp.frame;
        timestampLabelFrame.origin.y = (16 - timestampLabelFrame.size.height)*0.5;
        
        CGFloat timeStampLabelWidth = cell.messagetimestamp.frame.size.width+6;
        
        if (outgoing) {
            timeStampLabelWidth += 17;
            
            if ((message.isImageMessage && !message.isContactMessage) || message.isAttentionMessage || message.isAttentionMessage2) {
                textOnlyFrame = CGRectMake(320.*3./5.-8, kCellVerticalPadding+4, 320.*2./5., 320.*2./5.);
                bgFrame = CGRectMake(320.*3./5.-11, kCellVerticalPadding, textOnlyFrame.size.width+10, textOnlyFrame.size.height+7);
                videoPlayFrame = CGRectMake(bgFrame.origin.x+bgFrame.size.width/2-10, bgFrame.origin.y+bgFrame.size.height/2-10, 20, 20);
                timestampContainerFrame = CGRectMake(bgFrame.origin.x-timeStampLabelWidth-2, (320.*2./5.)*0.5, timeStampLabelWidth, 16.);
                timestampLabelFrame.origin.x = 20;
            } else {
                textOnlyFrame = CGRectMake(320.-14.-textSize.width, 5+kCellVerticalPadding, textSize.width, textSize.height);
                bgFrame = CGRectInset(textOnlyFrame, -14., -5);
                videoPlayFrame = CGRectZero;
                timestampContainerFrame = CGRectMake(bgFrame.origin.x-timeStampLabelWidth-2, bgFrame.origin.y+bgFrame.size.height-16., timeStampLabelWidth, 16.);
                timestampLabelFrame.origin.x = 20;
            }
        } else {
            if ((message.isImageMessage && !message.isContactMessage) || message.isAttentionMessage || message.isAttentionMessage2) {
                textOnlyFrame = CGRectMake(10., kCellVerticalPadding+4, 320.*2./5., 320.*2./5.);
                bgFrame = CGRectMake(0, kCellVerticalPadding, textOnlyFrame.origin.x+textOnlyFrame.size.width+3, textOnlyFrame.size.height+7);
                videoPlayFrame = CGRectMake(bgFrame.origin.x+bgFrame.size.width/2-10, bgFrame.origin.y+bgFrame.size.height/2-10, 20, 20);
                timestampContainerFrame = CGRectMake(bgFrame.origin.x+bgFrame.size.width+2, (320.*2./5.)*0.5, timeStampLabelWidth, 16.);
                timestampLabelFrame.origin.x = 3;
            } else {
                if(message.isGroupMessage && message.from.resource.length > 0) {
                    CGSize senderNameSize = [message.from.resource sizeWithFont:chatFont];
                    textSize = [messageStr sizeWithFont:chatFont constrainedToSize:CGSizeMake(320*2./3-senderNameSize.width, 2000) lineBreakMode:NSLineBreakByWordWrapping];
                    textSize.width += 3; textSize.height += 3;

                    textOnlyFrame = CGRectMake(14., 5+kCellVerticalPadding, textSize.width, textSize.height);
                    bgFrame = CGRectInset(textOnlyFrame, -14., -5);
                    videoPlayFrame = CGRectZero;
                    timestampContainerFrame = CGRectMake(bgFrame.origin.x+bgFrame.size.width+2, bgFrame.origin.y+bgFrame.size.height-16., timeStampLabelWidth, 16.);
                    timestampLabelFrame.origin.x = 3;

                } else {
                    textOnlyFrame = CGRectMake(14., 5+kCellVerticalPadding, textSize.width, textSize.height);
                    bgFrame = CGRectInset(textOnlyFrame, -14., -5);
                    videoPlayFrame = CGRectZero;
                    timestampContainerFrame = CGRectMake(bgFrame.origin.x+bgFrame.size.width+2, bgFrame.origin.y+bgFrame.size.height-16., timeStampLabelWidth, 16.);
                    timestampLabelFrame.origin.x = 3;
                }
            }
        }
        
        cell.message.frame = textOnlyFrame;
        cell.messageImage.frame = textOnlyFrame;
        cell.videoPlayImgView.frame = videoPlayFrame;
        cell.messageBG.frame = bgFrame;
        cell.timestampContainer.frame = timestampContainerFrame;
        cell.messagetimestamp.frame = timestampLabelFrame;
        cell.type = (message.isImageMessage && !message.isContactMessage) || message.isAttentionMessage || message.isAttentionMessage2?SMMessageTypeImage:SMMessageTypeText;
        
        cell.outgoing = outgoing;
        XMPPMessage *msg = [data valueForKey:@"text"];
        cell.messageSent.highlighted = msg.isDelivered;
        
        CGRect checkFrame = cell.messageSent.frame;
        checkFrame.origin.x = 3;
        cell.messageSent.frame = checkFrame;
        cell.backgroundColor = [UIColor clearColor];
        
        cell.retryBtn.hidden = YES;
    } else {
        // Resend message
        NSString *message = [data valueForKey:@"text"];
        
        NSString *messageStr = [self parseEmoticons:message];
        BOOL outgoing = [[data valueForKey:@"outgoing"] boolValue];
        NSDate *time = [data valueForKey:@"time"];
        
        NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
        [format setDateFormat:@"hh:mm a"];
        
        cell.message.font = chatFont;
        cell.message.text = messageStr;
        cell.message.textColor = [UIColor blackColor];
        
        cell.messagetimestamp.text = [format stringFromDate:time];
        [cell.messagetimestamp sizeToFit];
        
        CGSize textSize = [cell.message.text sizeWithFont:chatFont constrainedToSize:CGSizeMake(320*2./3., 2000) lineBreakMode:NSLineBreakByWordWrapping];
        textSize.width += 3; textSize.height += 3;

        CGRect textOnlyFrame;
        CGRect bgFrame;
        CGRect timestampContainerFrame;
        CGRect timestampLabelFrame = cell.messagetimestamp.frame;
        timestampLabelFrame.origin.y = (16 - timestampLabelFrame.size.height)*0.5;
        CGRect retryFrame;
        
        CGFloat timeStampLabelWidth = cell.messagetimestamp.frame.size.width+6;
        
        if (outgoing){
            timeStampLabelWidth += 17;

            textOnlyFrame = CGRectMake(320.-14.-textSize.width, 5+kCellVerticalPadding, textSize.width, textSize.height);
            bgFrame = CGRectInset(textOnlyFrame, -14., -5);
            timestampContainerFrame = CGRectMake(bgFrame.origin.x-timeStampLabelWidth-2, bgFrame.origin.y+bgFrame.size.height-16., timeStampLabelWidth, 16.);
            timestampLabelFrame.origin.x = 20;
            
            retryFrame = CGRectMake(timestampContainerFrame.origin.x, timestampContainerFrame.origin.y, timestampContainerFrame.size.height, timestampContainerFrame.size.height);
        }
        
        cell.message.frame = textOnlyFrame;
        cell.messageImage.frame = textOnlyFrame;
        cell.messageBG.frame = bgFrame;
        cell.timestampContainer.frame = timestampContainerFrame;
        cell.messagetimestamp.frame = timestampLabelFrame;
        cell.outgoing = outgoing;
        cell.retryBtn.frame = retryFrame;
        cell.retryBtn.hidden = NO;
        cell.retryBtn.tag = [[data valueForKey:@"id"] intValue];
        [cell.retryBtn addTarget:self action:@selector(retryMessage:) forControlEvents:UIControlEventTouchUpInside];
        
        CGRect checkFrame = cell.messageSent.frame;
        checkFrame.origin.x = 3;
        cell.messageSent.frame = checkFrame;
        cell.backgroundColor = [UIColor clearColor];
        cell.messageSent.hidden = YES;
    }
    
    return cell;
}

- (void)retryMessage:(UIButton *)sender {
    
    SMAppDelegate* delegate = (SMAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (![delegate reachability])
    {  // if internet is inactive
        return;
    }
    
    if (groupChat) {
        
    } else {
        if (blockButton.selected) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                            message:@"This user is blocked."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
    }
    
    NSMutableDictionary *msgDict = [[SMPersistentObject sharedObject] fetchResendMessageById:(int)sender.tag];
    NSString *strMessage = [msgDict valueForKey:@"text"];
    
    if (groupChat) {
        XMPPMessage *_message = [self.room sendMessage:strMessage];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", _message, @"text", nil];
        [chatData addObject:dict];
        displayChatData = [self convertDisplayChatData];
        [table reloadData];
        [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    } else {
        
        for (NSDictionary *dict in resendChatData) {
            if ([[dict valueForKey:@"message"] isKindOfClass:[NSString class]]) {
                if ([[dict valueForKey:@"id"] intValue] == sender.tag) {
                    [resendChatData removeObject:dict];
                    break;
                }
            }
        }
        displayChatData = [self convertDisplayChatData];
        [[SMPersistentObject sharedObject] deleteResendMessage:[[msgDict valueForKey:@"id"] intValue]];

        [[SMXMPPHandler XMPPHandler] sendMessage:strMessage to:self.withJID];
        [self stopIddleTimer];
        [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateActive toJID:withJID];
        myCurrentChatState = ChatStateActive;
        
        [self sendWakeUp];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [messageField resignFirstResponder];
    subChatButton.selected = YES;
    toggleMenuButton.selected = YES;
    [self subChatViewToggle:subChatButton];
    [self toggleSubMenu:toggleMenuButton];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    NSMutableArray *array = [displayChatData objectAtIndex:section];
    NSDictionary *data = [array objectAtIndex:0];
    NSDate *time = [data valueForKey:@"time"];
    
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"MMM dd, yyyy"];

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 35)];
    headerView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, headerView.frame.size.width, headerView.frame.size.height)];
    label.text = [format stringFromDate:time];
    label.font = [UIFont systemFontOfSize:17.0f];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    [headerView addSubview:label];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35.0f;
}

#pragma mark - HPGrowingTextViewDelegate

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    [self resizeInputView:diff stretch:YES];
}

- (void)resizeInputView:(CGFloat)diff stretch:(BOOL)bStretch {
    
	CGRect r = inputView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	inputView.frame = r;
    
    r = lightEffectImageView.frame;
    r.size.height -= diff/2;
    lightEffectImageView.frame = r;
    
    if (!bStretch) {
        r = msgBackgroundImageView.frame;
        r.size.height -= diff;
        msgBackgroundImageView.frame = r;
    }
    
    subChatButton.center = CGPointMake(subChatButton.center.x, inputView.center.y-inputView.frame.origin.y);
    sendMsgButton.center = CGPointMake(sendMsgButton.center.x, inputView.center.y-inputView.frame.origin.y);
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(self.groupChat){
        return YES;
    }
    
    NSString *str = [growingTextView.text stringByReplacingCharactersInRange:range withString:text];
    if(str.length < 1){
        [self stopIddleTimer];
        [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateActive toJID:self.withJID];
        myCurrentChatState = ChatStateActive;
        return YES;
    }
    
    if(myCurrentChatState != ChatStateComposing)
        [[SMXMPPHandler XMPPHandler] sendChatState:ChatStateComposing toJID:self.withJID];
    
    myCurrentChatState = ChatStateComposing;
    [self stopIddleTimer];
    iddleTimer = [NSTimer scheduledTimerWithTimeInterval:3. target:self selector:@selector(pauseTyping) userInfo:nil repeats:NO];
    return YES;
}

-(void)pauseTyping{
    [self stopIddleTimer];
    [[SMXMPPHandler XMPPHandler] sendChatState:ChatStatePaused toJID:self.withJID];
    myCurrentChatState = ChatStatePaused;
}

#pragma mark - delegate chat object
-(void)chatObjectPage:(SMChatObjectsSubPage *)subpage didSelectItem:(NSDictionary *)dict{
    
    NSInteger type = [[dict valueForKey:@"type"] integerValue];
    
    if(type == StickerTypeStickerGroup || type == StickerTypeIkoniaGroup){
        NSString *urlString = [dict valueForKey:@"url"];
        NSString *messageStr = [NSString stringWithFormat:@"%@%@", type==StickerTypeStickerGroup?kMessageKeySticker:kMessageKeyIkonia, urlString];
        [self subChatViewToggle:subChatButton];
        
        if(self.groupChat){
            XMPPMessage *_message = [self.room sendMessage:messageStr];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:_message, @"message", [NSNumber numberWithBool:YES], @"outgoing", [NSDate date], @"time", _message, @"text", nil];
            [chatData addObject:dict];
            displayChatData = [self convertDisplayChatData];
            [table reloadData];
            [table scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[displayChatData.lastObject count]-1 inSection:displayChatData.count-1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }else{
            [[SMXMPPHandler XMPPHandler] sendMessage:messageStr to:self.withJID];
        }
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLStickerUse]];
        [request setPostValue:self.myJID.user forKey:@"username"];
        [request setPostValue:[dict valueForKey:@"id"] forKey:@"sticker_id"];
        [queue addOperation:request];
        [request setCompletionBlock:^{
            //NSLog(@"result %@", [request responseString]);
        }];
        
        if(!self.groupChat){
            XMPPUserCoreDataStorageObject *me = [[SMXMPPHandler XMPPHandler] userWithJID:self.withJID];
            XMPPResourceCoreDataStorageObject *meRe = [[me.resources allObjects] lastObject];
            if(!meRe){
                ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLWakeup]];
                [request setPostValue:self.myJID.user forKey:@"username"];
                [request setPostValue:self.withJID.user forKey:@"targetname"];
                [request startAsynchronous];
            }
        }
    }else if(type == StickerTypeEmoticons){
        [self subChatViewToggle:subChatButton];
        NSString *plain = [dict valueForKey:@"plain"];
        
        if(!messageField.isFirstResponder){
            messageField.text = [messageField.text stringByAppendingString:plain];
        }else{
//            [messageField insertText:plain];
            [messageField.internalTextView insertText:plain];
        }
    }else if(type == StickerTypeAttachment){
        [self subChatViewToggle:subChatButton];
        NSInteger tag = [[dict valueForKey:@"tag"] integerValue];
        
        if(tag == 0){
            [self pow:nil];
        }else if(1 <= tag && tag <= 3){
            UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
            pickerImage.delegate = self;
            pickerImage.allowsEditing = YES;
            
            if(tag < 3){
                pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                if(tag == 1){
                     pickerImage.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
                }else{
                     pickerImage.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeMovie, nil];
                }
            }else{
                pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
                pickerImage.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
            }
            
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
            {
                UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
                window.clipsToBounds = YES;
                [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
                
                window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
                window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
            }
            
            [self presentViewController:pickerImage animated:YES completion:nil];
            [pickerImage release];
        }else if(tag == 4){
            [messageField resignFirstResponder];
            [soundRecord reset];
            [self.view addSubview:soundRecord.view];
            [soundRecord show];
        }else if(tag == 5){
            SMContactSelectPage *select = [[SMContactSelectPage alloc] init];
            select.multiselect = NO;
            select.data = [[SMPersistentObject sharedObject] contactArrayWithPhone];
            select.isEmail = NO;
            select.singleSelectDelegate = self;
            [self.navigationController pushViewController:select animated:YES];
            [select release];
        }else if(tag == 6){
            SMAppConfig *config = [SMAppConfig sharedConfig];
            messageField.text = [NSString stringWithFormat:@"%@LAT:%@/LONG:%@", kMessageKeyLocation, config.latitudeStr, config.longitudeStr];
            [self sendMessage:nil];
        }
    }
}

#pragma mark - delegate ImagePicker
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }
    
    if(queue.operationCount > 0){
        return;
    }
    
    NSString *type = [info valueForKey:@"UIImagePickerControllerMediaType"];
    NSData *data = nil;
    NSString *mime = nil;
    NSString *file = nil;
    
    NSString *uploadType = @"private";
    if(self.groupChat){
        NSString *domain = self.withJID.domain;
        if([domain isEqualToString:@"room.lb1.smilesatme.com"]){
            uploadType = @"room";
        }else{
            uploadType = @"group";
        }
    }
    
    if([type isEqualToString:@"public.image"]){
        UIImage *image = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
        
        data = UIImageJPEGRepresentation(image, 0.7);
        mime = @"image/jpeg";
        file = @"myimage.jpg";
        
        // ---------------- WCL - 2014/2/27 - No.24 --------------
        CGRect cropRect;
        cropRect = [[info valueForKey:@"UIImagePickerControllerCropRect"] CGRectValue];
        
        CGSize finalSize = CGSizeMake(1280,1280);
        image = [self cropImage:image cropRect:cropRect aspectFitBounds:finalSize fillColor:[UIColor clearColor]];
        data = UIImageJPEGRepresentation(image, 1.0);
        // ---------------- WCL - 2014/2/27 - No.24 --------------

        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUploadFiles]];
        [request setPostValue:self.myJID.user forKey:@"username"];
        [request setData:data withFileName:file andContentType:mime forKey:@"file"];
        [request setPostValue:uploadType forKey:@"type"];
        request.delegate = self;
        request.uploadProgressDelegate = progressAlert;
        [queue addOperation:request];
    }else if([type isEqualToString:@"public.movie"]){
        NSURL *url = [info valueForKey:@"UIImagePickerControllerMediaURL"];
        data = [NSData dataWithContentsOfURL:url];
        mime = @"video/quicktime";
        file = [url lastPathComponent];
        
        double lenInMB = (data.length / 1024.0f) / 1024.0f;
        
        if (lenInMB <= 10) {
            [self uploadMovieURL:url data:data mime:mime filename:file uploadType:uploadType];
        } else {
            [[[[UIAlertView alloc] initWithTitle:@"" message:@"Video should be less than 10MB." delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] autorelease] show];
        }
    }
}

-(UIImage *)cropImage:(UIImage *)sourceImage cropRect:(CGRect)cropRect aspectFitBounds:(CGSize)finalImageSize fillColor:(UIColor *)fillColor {
    
    CGImageRef sourceImageRef = sourceImage.CGImage;
    
    //Since the crop rect is in UIImageOrientationUp we need to transform it to match the source image.
    CGAffineTransform rectTransform = [self transformSize:sourceImage.size orientation:sourceImage.imageOrientation];
    CGRect transformedRect = CGRectApplyAffineTransform(cropRect, rectTransform);
    
    //Now we get just the region of the source image that we are interested in.
    CGImageRef cropRectImage = CGImageCreateWithImageInRect(sourceImageRef, transformedRect);
    
    //Figure out which dimension fits within our final size and calculate the aspect correct rect that will fit in our new bounds
    CGFloat horizontalRatio = finalImageSize.width / CGImageGetWidth(cropRectImage);
    CGFloat verticalRatio = finalImageSize.height / CGImageGetHeight(cropRectImage);
    CGFloat ratio = MIN(horizontalRatio, verticalRatio); //Aspect Fit
    CGSize aspectFitSize = CGSizeMake(CGImageGetWidth(cropRectImage) * ratio, CGImageGetHeight(cropRectImage) * ratio);
    
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 finalImageSize.width,
                                                 finalImageSize.height,
                                                 CGImageGetBitsPerComponent(cropRectImage),
                                                 0,
                                                 CGImageGetColorSpace(cropRectImage),
                                                 CGImageGetBitmapInfo(cropRectImage));
    
    if (context == NULL) {
        NSLog(@"NULL CONTEXT!");
    }
    
    //Fill with our background color
    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, finalImageSize.width, finalImageSize.height));
    
    //We need to rotate and transform the context based on the orientation of the source image.
    CGAffineTransform contextTransform = [self transformSize:finalImageSize orientation:sourceImage.imageOrientation];
    CGContextConcatCTM(context, contextTransform);
    
    //Give the context a hint that we want high quality during the scale
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    //Draw our image centered vertically and horizontally in our context.
    CGContextDrawImage(context, CGRectMake((finalImageSize.width-aspectFitSize.width)/2, (finalImageSize.height-aspectFitSize.height)/2, aspectFitSize.width, aspectFitSize.height), cropRectImage);
    
    //Start cleaning up..
    CGImageRelease(cropRectImage);
    
    CGImageRef finalImageRef = CGBitmapContextCreateImage(context);
    UIImage *finalImage = [UIImage imageWithCGImage:finalImageRef];
    
    CGContextRelease(context);
    CGImageRelease(finalImageRef);
    return finalImage;
}

//Creates a transform that will correctly rotate and translate for the passed orientation.
//Based on code from niftyBean.com
- (CGAffineTransform) transformSize:(CGSize)imageSize orientation:(UIImageOrientation)orientation {
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (orientation) {
        case UIImageOrientationLeft: { // EXIF #8
            CGAffineTransform txTranslate = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            CGAffineTransform txCompound = CGAffineTransformRotate(txTranslate,M_PI_2);
            transform = txCompound;
            break;
        }
        case UIImageOrientationDown: { // EXIF #3
            CGAffineTransform txTranslate = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            CGAffineTransform txCompound = CGAffineTransformRotate(txTranslate,M_PI);
            transform = txCompound;
            break;
        }
        case UIImageOrientationRight: { // EXIF #6
            CGAffineTransform txTranslate = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            CGAffineTransform txCompound = CGAffineTransformRotate(txTranslate,-M_PI_2);
            transform = txCompound;
            break;
        }
        case UIImageOrientationUp: // EXIF #1 - do nothing
        default: // EXIF 2,4,5,7 - ignore
            break;
    }
    return transform;
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)uploadMovieURL:(NSURL *)url data:(NSData *)data mime:(NSString *)mime filename:(NSString *)filename uploadType:(NSString *)type
{
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    [asset release];
    CMTime thumbTime = CMTimeMakeWithSeconds(0,30);
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        if (result != AVAssetImageGeneratorSucceeded) {
            NSLog(@"couldn't generate thumbnail, error:%@", error);
        }
        
        UIImage *thumbImg = [UIImage imageWithCGImage:im];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUploadFiles]];
        [request setPostValue:self.myJID.user forKey:@"username"];
        [request setData:data withFileName:filename andContentType:mime forKey:@"file"];
        [request setPostValue:type forKey:@"type"];
        [request setData:UIImageJPEGRepresentation(thumbImg, 0.7) withFileName:@"thumb.jpg" andContentType:@"image/jpeg" forKey:@"thumb"];
        request.delegate = self;
        request.uploadProgressDelegate = progressAlert;
        [queue addOperation:request];
        
        [generator release];
    };
    
    CGSize maxSize = CGSizeMake(320, 180);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:handler];
    
}

#pragma mark - delegate http
-(void)requestStarted:(ASIHTTPRequest *)request{
    
    if (request.tag == 10) {
        // if block check
        return;
    }
    
    alertContainer.alpha = 0.;
    alertContainer.hidden = NO;
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    alertContainer.alpha = 1.0;
    [UIView commitAnimations];
    
    if(request.tag == 0)
        alertLabel.text = @"Uploading file...";
    else
        alertLabel.text = @"Downloading file...";
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    if (request.tag == 10) {
        // if block check
        [self sendMessage1:NO blockedFriend:nil];
        return;
    }
    
    alertLabel.text = @"Failed to contact server.";
    [self performSelector:@selector(hideAlertContainer) withObject:nil afterDelay:1.];
}

-(void)hideAlertContainer{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    alertContainer.alpha = 0.0;
    [UIView commitAnimations];
    
    [alertContainer performSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.25];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    if(request.tag == 0){
        NSDictionary *response = [[request responseString] JSONValue];
        NSString *status = [response valueForKey:@"STATUS"];
     
        if([status isEqualToString:@"SUCCESS"]){
            alertLabel.text = @"File was sent.";
            NSString *type = @"IMAGE";
            
            if([[response valueForKey:@"EXT"] isEqualToString:@"mov"]){
                type = @"VIDEO";
            }else if([[response valueForKey:@"EXT"] isEqualToString:@"wav"]){
                type = @"AUDIO";
            }
            
            NSString *url = [response valueForKey:@"URL"];
            
            if([url rangeOfString:@"http://"].length < 1)
                url = [@"http://api.smilesatme.com/" stringByAppendingString:url];
            
            messageField.text = [NSString stringWithFormat:@"%@TYPE:%@/DESC:%@/URL:%@/THUMB:%@", kMessageKeyFile, type, [response valueForKey:@"EXT"], url, [response valueForKey:@"THUMB"]];
            [self sendMessage:nil];
        }else{
            alertLabel.text = [response valueForKey:@"MESSAGE"];
        }
    }else if(request.tag == 1){
        NSData *data = [request responseData];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[request.url lastPathComponent]];
        [data writeToFile:path atomically:YES];
        
        if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)){
            UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(image:didFinishSavingWithError:ontextInfo:), nil);
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Video format is not compatible with iOS album." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }else if(request.tag == 2){
        NSData *data = [request responseData];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[request.url lastPathComponent]];
        [data writeToFile:path atomically:YES];
        
        UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:data], self, @selector(image:didFinishSavingWithError:ontextInfo:), nil);
    }else if(request.tag == 3){
        NSData *data = [request responseData];
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[request.url lastPathComponent]];
        [data writeToFile:path atomically:YES];
        
        if(temporaryURL){
            [temporaryURL release];
            temporaryURL = nil;
        }
        
        temporaryURL = [path retain];
        
        QLPreviewController *quickLookPreview = [[QLPreviewController alloc]init];
        [quickLookPreview setDataSource:self];
        [self presentViewController:quickLookPreview animated:YES completion:nil];
        [quickLookPreview release];
    }else if(request.tag == 4){
        NSData *data = [request responseData];
        [messageField resignFirstResponder];
        soundPlayer.soundData = data;
        [self.view addSubview:soundPlayer.view];
        [soundPlayer reset];
        [soundPlayer show];
    } else if (request.tag == 10) {
        // if block check
        NSDictionary *response = [[request responseString] JSONValue];
        [self sendMessage1:YES blockedFriend:[response objectForKey:@"DATA"]];
        return;
    }
    
    [self performSelector:@selector(hideAlertContainer) withObject:nil afterDelay:1.];
}

#pragma mark - Actionsheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [actionSheet release];
    
    NSDictionary *dict = [temporaryString JSONValue];
    
    if(actionSheet.tag == 0){
        NSString *type = [dict valueForKey:@"type"];

        if([type isEqualToString:@"VIDEO"]){
            if(buttonIndex == 0){
                MPMoviePlayerViewController *movie = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[dict valueForKey:@"url"]]];
                [self presentViewController:movie animated:YES completion:nil];
                [movie release];
            }else if(buttonIndex == 1){
                NSString *urlStr = [dict valueForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlStr];
                
                ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
                req.delegate = self;
                req.downloadProgressDelegate = progressAlert;
                [queue addOperation:req];
                req.tag = 1;
            }
        }else if([type isEqualToString:@"IMAGE"]){
            if(buttonIndex == 0){
                NSString *urlStr = [dict valueForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlStr];
                
                ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
                req.delegate = self;
                req.downloadProgressDelegate = progressAlert;
                [queue addOperation:req];
                req.tag = 3;
            }else if(buttonIndex == 1){
                NSString *urlStr = [dict valueForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlStr];
                
                ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
                req.delegate = self;
                req.downloadProgressDelegate = progressAlert;
                [queue addOperation:req];
                req.tag = 2;
            }
        }else if([type isEqualToString:@"AUDIO"]){
            if(buttonIndex == 0){
                NSString *urlStr = [dict valueForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlStr];
                
                ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
                req.delegate = self;
                req.downloadProgressDelegate = progressAlert;
                [queue addOperation:req];
                req.tag = 4;
            }
        }
    }else if(actionSheet.tag == 1 && buttonIndex == 0){
        NSString *latitude = [dict valueForKey:@"latitude"];
        NSString *longitude = [dict valueForKey:@"longitude"];
        SMAppConfig *config = [SMAppConfig sharedConfig];
        
        UIApplication *app = [UIApplication sharedApplication];
        [app openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.google.com/maps?ll=%@,%@&daddr=%@,%@&saddr=%@,%@", latitude, longitude, latitude, longitude, config.latitudeStr, config.longitudeStr]]];
    }else if(actionSheet.tag == 2){
        NSString *phone = [dict valueForKey:@"phone"];
        if(buttonIndex == 0){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[dict valueForKey:@"name"] message:[dict valueForKey:@"phone"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }else if(buttonIndex == 1){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phone]]];
        }else if(buttonIndex == 2){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", phone]]];
        }
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error ontextInfo:(void *)contextInfo{
    NSString *message = @"File has successfully saved.";
    
    if(error){
        message = error.localizedDescription;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

#pragma mark - datasource prevoew
- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller {
    return 1;
}

- (id <QLPreviewItem>) previewController: (QLPreviewController *) controller previewItemAtIndex: (NSInteger) index {
    return [NSURL URLWithString:[@"file:/" stringByAppendingString:temporaryURL]];
}

#pragma mark - ContactSelect
-(void)didSelectContact:(NSDictionary *)contact{
    messageField.text = [NSString stringWithFormat:@"%@TYPE:CONTACT/NAME:%@/NUMBER:%@", kMessageKeyFile, [contact valueForKey:@"name"], [contact valueForKey:@"phone"]];
    [self sendMessage:nil];
}

#pragma mark - delegate soundRecorder
-(void)soundDidRecorded{
    NSString *uploadType = @"private";
    if(self.groupChat){
        NSString *domain = self.withJID.domain;
        if([domain isEqualToString:@"room.lb1.smilesatme.com"]){
            uploadType = @"room";
        }else{
            uploadType = @"group";
        }
    }
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUploadFiles]];
    [request setPostValue:self.myJID.user forKey:@"username"];
    [request setData:soundRecord.data withFileName:@"myRecord.wav" andContentType:@"audio/wav" forKey:@"file"];
    [request setPostValue:uploadType forKey:@"type"];
    request.delegate = self;
    request.uploadProgressDelegate = progressAlert;
    [queue addOperation:request];
}

#pragma mark - Convert Display Data

- (NSMutableArray *)convertDisplayChatData {

    NSMutableArray *convertArray = [[NSMutableArray alloc] init];
    [convertArray removeAllObjects];
    
    NSMutableArray *originalArray = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in chatData) {
        [originalArray addObject:dict];
    }
    for (NSDictionary *dict in resendChatData) {
        [originalArray addObject:dict];
    }
    
    for (int i=0; i<[originalArray count]; i++) {
        NSDictionary *data = [originalArray objectAtIndex:i];
        NSDate *time = [data valueForKey:@"time"];
        
        NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
        [format setDateFormat:@"MM/DD/yyyy"];
        
        NSString *strDate = [format stringFromDate:time];
        NSDate *newTime = [format dateFromString:strDate];

        int nIndex = [self getIndexFromDisplayChatDataArray:convertArray sort:newTime];
        if (nIndex == -1) {
            NSMutableArray *subArray = [[NSMutableArray alloc] init];
            [subArray addObject:data];
            [convertArray addObject:subArray];
        } else {
            BOOL bInserted = NO;
            NSMutableArray *subArray = [convertArray objectAtIndex:nIndex];
            for (int j=0; j<[subArray count]; j++) {
                NSDictionary *subData = [subArray objectAtIndex:j];
                NSDate *subTime = [subData valueForKey:@"time"];
                
                if ([time compare:subTime] == NSOrderedAscending) {
                    [subArray insertObject:data atIndex:j];
                    bInserted = YES;
                    break;
                }
            }
            
            if (!bInserted) {
                [subArray addObject:data];
            }
        }
    }

    return convertArray;
}

- (int)getIndexFromDisplayChatDataArray:(NSMutableArray *)array sort:(NSDate *)sortDate {

    for (int j=0; j<[array count]; j++) {
        NSMutableArray *subArray = [array objectAtIndex:j];
        
        for (int k=0; k<[subArray count]; k++) {
            
            NSDictionary *data = [subArray objectAtIndex:k];
            NSDate *time = [data valueForKey:@"time"];
            
            NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
            [format setDateFormat:@"MM/DD/yyyy"];
            
            NSString *strDate = [format stringFromDate:time];
            NSDate *newTime = [format dateFromString:strDate];
            
            if ([newTime compare:sortDate] == NSOrderedSame) {
                return j;
            }
        }
    }
    
    return -1;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
