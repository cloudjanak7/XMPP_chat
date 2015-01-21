//
//  SMContactSelectPage.m
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMContactSelectPage.h"
#import "SMPersistentObject.h"
#import <MessageUI/MessageUI.h>
#import "SMMyUserProfile.h"
#import "SMXMPPHandler.h"
#import <AddressBook/AddressBook.h>

@interface SMContactSelectPage () <UITextFieldDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate>{
    IBOutlet UITextField *searchField;
    IBOutlet UITableView *table;
    IBOutlet UIButton *doneButton;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)done:(id)sender;

@property (nonatomic, retain) NSArray *tempData;

@end

@implementation SMContactSelectPage

@synthesize data, tempData, isEmail, multiselect, singleSelectDelegate;

- (void)dealloc
{
    [tempData release];
    [data release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
    {
        CGRect rect = [[UIScreen mainScreen] bounds];
        if (rect.size.height > 500) {
            
        }
        else {
            
        }
        
        
    }
    /*
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
    
    for ( int i = 0; i < nPeople; i++ )
    {
        ABRecordRef ref = CFArrayGetValueAtIndex( allPeople, i );
        
        
    }
     */
    self.tempData = self.data;
    
    if(!self.multiselect)
        doneButton.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - ACtion
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    [searchField resignFirstResponder];
}

-(void)done:(id)sender{
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    NSString *user = profile.fullname;
    
    NSString *message = [NSString stringWithFormat:@"Hi Friend,\nI'm using SMILES app, you can download at http://smilesatme.com/download.\nSee you there.\n\n%@", user];
    
    if(self.isEmail){
        NSMutableArray *recipients = [NSMutableArray array];
        for(NSDictionary *dict in self.data){
            if([[dict valueForKey:@"selected"] boolValue]){
                [recipients addObject:[dict valueForKey:kTableFieldEmail]];
            }
        }
        
        MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
        emailComposer.mailComposeDelegate = self;
        [emailComposer setSubject:@"Fun Apps"];
        [emailComposer setTitle:@"SMILES"];
        [emailComposer setToRecipients:recipients];
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
        [self presentViewController:emailComposer animated:YES completion:nil];
    }else{
        NSMutableArray *recipients = [NSMutableArray array];
        for(NSDictionary *dict in self.data){
            if([[dict valueForKey:@"selected"] boolValue]){
                [recipients addObject:[dict valueForKey:kTableFieldPhone]];
            }
        }
        
        if([MFMessageComposeViewController canSendText]){
            MFMessageComposeViewController *smsComposer =
            [[MFMessageComposeViewController alloc] init];
            
            smsComposer.recipients = recipients;
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
    }
}

#pragma mark - delegate dan data source tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tempData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"contactcell"];
    
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"contactcell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check-list-unfocus.png"]];
        [imageView setHighlightedImage:[UIImage imageNamed:@"check-list-focus.png"]];
        cell.accessoryView = imageView;
        [imageView release];
    }
    
    NSDictionary *dict = [self.tempData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict valueForKey:kTableFieldName];
    
    NSString *detail = [dict valueForKey:kTableFieldEmail];
    if(!detail)
        detail = [dict valueForKey:kTableFieldPhone];
    cell.detailTextLabel.text = detail;
    
    NSString* registered = [dict valueForKey:@"registered"];
    if (registered != nil) {
        if ([registered isEqualToString:@"1"]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
        }
    }
    else
    {
        UIImageView *img = (UIImageView *) cell.accessoryView;
        img.highlighted = [[dict valueForKey:@"selected"] boolValue];
        if(!self.multiselect)
            img.hidden = YES;
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //[tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = [self.tempData objectAtIndex:indexPath.row];
    
    NSString* registered = [dict valueForKey:@"registered"];
    if (registered != nil) {
        if ([registered isEqualToString:@"1"]) {
            return;
        }
    }
    if(self.multiselect){
        NSMutableDictionary *dict = [self.tempData objectAtIndex:indexPath.row];
        BOOL val = [[dict valueForKey:@"selected"] boolValue];
        [dict setValue:[NSNumber numberWithBool:!val] forKey:@"selected"];
        
        [tableView reloadData];
        [self hideKeyboard:nil];
    }else{
        NSMutableDictionary *dict = [self.tempData objectAtIndex:indexPath.row];
        [self.singleSelectDelegate didSelectContact:dict];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - delegate TextField
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *result = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(result.length > 0){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", result];
        self.tempData = [self.data filteredArrayUsingPredicate:predicate];
    }else{
        self.tempData = self.data;
    }
    
    [table reloadData];
    return YES;
}

-(BOOL)textFieldShouldClear:(UITextField *)textField{
    self.tempData = self.data;
    [table reloadData];
    return YES;
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

@end
