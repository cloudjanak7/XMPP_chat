//
//  SMCreateGroupPage.m
//  SMILES
//
//  Created by asepmoels on 7/23/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMCreateGroupPage.h"
#import "SMStandardTextField.h"
#import "SMStandardTableDelegate.h"
#import "SMXMPPHandler.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "SMChatPage.h"
#import "XMPPRoom.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMPersistentObject.h"

@interface SMCreateGroupPage () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SMStandarTalbePickingDelegate, SMXMPPHandlerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    IBOutlet SMStandardTextField *groupName;
    IBOutlet SMStandardTextField *participants;
    IBOutlet UITableView *mainTable;
    IBOutlet UITableView *popupTable;
    IBOutlet UILabel *participantLabel;
    IBOutlet UIImageView *avatarGroup;
    
    SMStandardTableDelegate *delegatePopup;
    NSMutableArray *participantData;
    BOOL needToPop;
    BOOL imageIsChanged;
    BOOL onlyInviteAdmin;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)toggleCheck:(id)sender;
-(IBAction)create:(id)sender;

@end

@implementation SMCreateGroupPage

- (void)dealloc
{
    [delegatePopup release];
    [participantData release];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    delegatePopup = [[SMStandardTableDelegate alloc] init];
    participantData = [[NSMutableArray alloc] init];
    
    delegatePopup.delegate = self;
    popupTable.delegate = delegatePopup;
    popupTable.dataSource = delegatePopup;
    [mainTable addSubview:popupTable];
    CGRect frame = popupTable.frame;
    frame.origin.y = participants.frame.size.height + participants.frame.origin.y - 2;
    popupTable.frame = frame;
    
    avatarGroup.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeAvatar)];
    [avatarGroup addGestureRecognizer:tap];
    [tap release];
    
    onlyInviteAdmin = YES;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(needToPop){
        [self back:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];

    CGRect rect = [[userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = mainTable.frame;
    frame.size.height = self.view.frame.size.height - rect.size.height - frame.origin.y;
    mainTable.frame = frame;
    
    frame = popupTable.frame;
    frame.size.height = self.view.frame.size.height - rect.size.height - frame.origin.y;
    popupTable.frame = frame;
    [UIView commitAnimations];
}

-(void)keyboardDidHide:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];

    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = mainTable.frame;
    frame.size.height = self.view.frame.size.height - frame.origin.y;
    mainTable.frame = frame;
    
    frame = popupTable.frame;
    frame.size.height = self.view.frame.size.height - frame.origin.y;
    popupTable.frame = frame;
    
    [UIView commitAnimations];
}

#pragma mark - Action
-(void)back:(id)sender{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    [groupName resignFirstResponder];
    [participants resignFirstResponder];
    popupTable.hidden = YES;
}

-(void)toggleCheck:(UIButton *)sender{
    [self hideKeyboard:nil];
    sender.selected = !sender.selected;
    
    onlyInviteAdmin = !onlyInviteAdmin;
}

-(void)create:(id)sender{
    if(groupName.text.length < 1){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Can not create group with empty name" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    if(participantData.count < 1){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Group must be more than 2 person." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
    [[SMXMPPHandler XMPPHandler] createGroup:groupName.text];
}

-(void)changeAvatar{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", @"Camera", nil];
        sheet.tag = 3;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", nil];
        sheet.tag = 2;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }
}

#pragma mark - delegate XMPPHandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeGroupReady){
        XMPPRoom *room = [info valueForKey:@"sender"];
        for(NSDictionary *dict in participantData){
            XMPPJID *jid = [dict valueForKey:@"jid"];
            if (jid) {
                [room inviteUser:jid withMessage:[NSString stringWithFormat:@"Please join to group. :)%@", [NSString stringWithFormat:@"info=%@|%d", [SMXMPPHandler XMPPHandler].myJID.user, onlyInviteAdmin]]];
                NSLog(@"sent invitation to %@", jid.user);
//                [room inviteUser:jid withMessage:@"Please join to group. :)"];
            }
        }
        [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
        
        /*
        SMChatPage *chat = [[SMChatPage alloc] init];
        chat.myJID = [SMXMPPHandler XMPPHandler].myJID;
        chat.withJID = room.roomJID;
        chat.groupChat = YES;
        chat.room = room;
        [self.navigationController pushViewController:chat animated:NO];
        [chat release];
         
        SMCreateGroupPage *c = [[[SMCreateGroupPage alloc] init] autorelease];
        [self.navigationController pushViewController:c animated:YES];*/

        [[SMXMPPHandler XMPPHandler] addGroupName:room.roomJID.user withJID:room.roomJID andThumb:(imageIsChanged?avatarGroup.image:nil)];
        needToPop = YES;
        
        [[SMPersistentObject sharedObject] addOnlyInviteAdmin:room.roomJID.user bare:room.roomJID.bare adminUser:[SMXMPPHandler XMPPHandler].myJID.user onlyInviteAdmin:onlyInviteAdmin];
    }
}

#pragma mark - delegate dan data source table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return participantData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"participantscell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)] autorelease];
        [btn setImage:[UIImage imageNamed:@"cros-icon"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = btn;
    }
    
    NSDictionary *dict = [participantData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict valueForKey:SMStandardTableFieldName];
    cell.imageView.image = [dict valueForKey:SMStandardTableFieldPhoto];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:12.];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.textLabel.highlightedTextColor = [UIColor darkGrayColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    cell.textLabel.shadowColor = [UIColor whiteColor];
    
    cell.accessoryView.tag = indexPath.row;
    
    if(cell.imageView.image == nil){
        cell.imageView.image = [UIImage imageNamed:@"icon-group.png"];
    }
    
    return cell;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 1;
}

-(void)deleteItem:(UIButton *)sender{
    [participantData removeObjectAtIndex:sender.tag];
    [mainTable reloadData];
    participantLabel.text = [NSString stringWithFormat:@"(%lu/30)", (unsigned long)participantData.count];
}

#pragma mark - delegate UITextField
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *finalString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if(finalString.length < 1){
        popupTable.hidden = YES;
        return YES;
    }
    
    popupTable.hidden = NO;
    [self updatePopupForString:finalString];
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return NO;
}

-(void)updatePopupForString:(NSString *)str{
    NSMutableArray *newArray = [NSMutableArray array];
    
    NSMutableArray *addToContact = [NSMutableArray array];
    for (XMPPUserCoreDataStorageObject *user in [[SMXMPPHandler XMPPHandler] allFriend]) {
        
        if(([user.subscription isEqualToString:@"from"] || [user.subscription isEqualToString:@"none"]) && [user.ask isEqualToString:@"subscribe"]) // Approval pending...
            continue;
        
        if ([user.subscription isEqualToString:@"to"])  // block
            continue;
        
        [addToContact addObject:user];
    }
    
    for(XMPPUserCoreDataStorageObject *friend in addToContact){
        if([friend.jid.bare rangeOfString:str].length > 0){
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:friend.jid.user, SMStandardTableFieldName, friend.photo,SMStandardTableFieldPhoto, friend.jid, @"jid", nil];
            if ([participantData indexOfObject:dict] == NSNotFound) {
                [newArray addObject:dict];
            }
        }
    }
    delegatePopup.data = newArray;
    [popupTable reloadData];
    
    if(newArray.count > 0){
        popupTable.hidden = NO;
    }else{
        popupTable.hidden = YES;
    }
}

#pragma mark - delegate picking popup table
-(void)SMStandarTable:(SMStandardTableDelegate *)table didPickedItem:(NSDictionary *)dict{
    [participants resignFirstResponder];
    participants.text = @"";
    popupTable.hidden = YES;
    
    if(participantData.count >= 30){
        return;
    }
    
    [participantData addObject:dict];
    [mainTable reloadData];
    participantLabel.text = [NSString stringWithFormat:@"(%lu/30)", (unsigned long)participantData.count];
}

#pragma mark - delegate Actionsheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [actionSheet release];
    if(buttonIndex >= actionSheet.tag)return;
    
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    pickerImage.delegate = self;
    pickerImage.allowsEditing = YES;
    
    if(buttonIndex == 0){
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }else if(buttonIndex == 1){
        pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }else if(buttonIndex == 2){
        pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerImage.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
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
    
    imageIsChanged = YES;
    
    avatarGroup.image = [[info valueForKey:@"UIImagePickerControllerEditedImage"] retain];
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

@end
