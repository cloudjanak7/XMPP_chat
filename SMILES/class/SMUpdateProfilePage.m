//
//  SMUpdateProfilePage.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMUpdateProfilePage.h"
#import "SMMyUserProfile.h"
#import "SMXMPPHandler.h"
#import "EGOImageView.h"
#import "SMChangePasswordPage.h"
#import "SMSelectDatePage.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"
#import "JSON.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMLeftMenuPage.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "XMPPvCardTemp.h"
#import "EGOCache.h"
#import "UIImage+Utilities.h"

inline static NSString* keyForURL(NSURL* url, NSString* style) {
	if(style) {
		return [NSString stringWithFormat:@"EGOImageLoader-%lu-%lu", (unsigned long)[[url description] hash], (unsigned long)[style hash]];
	} else {
		return [NSString stringWithFormat:@"EGOImageLoader-%lu", (unsigned long)[[url description] hash]];
	}
}

@interface SMUpdateProfilePage () <UITableViewDataSource, UITableViewDelegate, SMSelectDatePageDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    IBOutlet UIView *section0View;
    IBOutlet UIView *section1View;
    IBOutlet UIView *section2View;
    IBOutlet UITableView *mainTable;
    IBOutlet UITextField *displayName;
    IBOutlet UITextField *personalMessage;
    IBOutlet UIButton *male;
    IBOutlet UIButton *female;
    IBOutlet EGOImageView *foto;
    
    NSMutableDictionary *data;
    NSDate *selectedDate;
    MBProgressHUD *loading;
    NSOperationQueue *queue;
    UIImage *editedImage;
    UIImage *originalImage;
    BOOL imageIsChanged;
    NSInteger requestCount;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)selectGender:(id)sender;
-(IBAction)updateProfile:(id)sender;
-(IBAction)changePhoto:(id)sender;

@end

@implementation SMUpdateProfilePage

- (void)dealloc
{
    [selectedDate release];
    [data release];
    [queue release];
    [editedImage release];
    [originalImage release];
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
    data = [[NSMutableDictionary alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
    [self refreshView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)refreshView{
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    
    displayName.text = profile.fullname;
    personalMessage.text = profile.status;
    
    if([profile.gender isEqualToString:@"pria"]){
        male.selected = YES;
        female.selected = NO;
    }else{
        male.selected = NO;
        female.selected = YES;
    }
    
    if(profile.birthday){
        NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
        [format setDateFormat:@"dd MMMM yyyy"];
        NSString *birth = [format stringFromDate:profile.birthday];
        [data setValue:birth forKey:@"birthday"];
        selectedDate = [profile.birthday retain];
    }
    
    if(profile.avatarThumb){
        foto.imageURL = [NSURL URLWithString:profile.avatarThumb];
    }
    
    if(editedImage)
        [editedImage release];
    
    editedImage = [foto.image retain];
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
    [UIView commitAnimations];
}

-(void)back:(id)sender{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    [displayName resignFirstResponder];
    [personalMessage resignFirstResponder];
}

-(void)selectGender:(id)sender{
    if(sender == male){
        male.selected = YES;
        female.selected = NO;
    }else{
        male.selected = NO;
        female.selected = YES;
    }
}

-(void)updateProfile:(id)sender{
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUpdateProfile]];
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    
    BOOL bProfileUpdated = NO;
    
    if (![profile.fullname isEqualToString:displayName.text]) {
        bProfileUpdated = YES;
    }
    
    if (![profile.status isEqualToString:personalMessage.text]) {
        bProfileUpdated = YES;
    }
    
    if (![profile.gender isEqualToString:(male.selected?@"pria":@"wanita")]) {
        bProfileUpdated = YES;
    }
    
    if ([profile.birthday compare:selectedDate] != NSOrderedSame) {
        bProfileUpdated = YES;
    }
    
    if (imageIsChanged) {
        bProfileUpdated = YES;
    }
    
    if (!bProfileUpdated) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"Your profile didn't update."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [request setPostValue:profile.username forKey:@"username"];
    [request setPostValue:displayName.text forKey:@"fullname"];
    [request setPostValue:[data valueForKey:@"birthday"] forKey:@"dob"];
    [request setPostValue:male.selected?@"pria":@"wanita" forKey:@"gender"];
    [request setPostValue:@"ID" forKey:@"country"];
    request.delegate = self;
    request.tag = 1;
    [queue addOperation:request];
    requestCount = 1;
    
    if(imageIsChanged){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUploadAvatar]];
        request.delegate = self;
        request.tag = 2;
        [request setPostValue:profile.username forKey:@"username"];
        NSData *imageData = UIImageJPEGRepresentation(editedImage, 0.7);
        [request setData:imageData withFileName:@"myphoto.jpg" andContentType:@"image/jpeg" forKey:@"image"];
        [queue addOperation:request];
        requestCount++;
    }
}

-(IBAction)changePhoto:(id)sender{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", @"Camera", nil];
        sheet.tag = 3;
        [sheet showInView:self.view];
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", nil];
        sheet.tag = 2;
        [sheet showInView:self.view];
    }
}

#pragma mark - delegate dan data source table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 1)return 2;
    
    return 0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 34;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(section == 0)
        return section0View;
    else if(section == 1)
        return section1View;
    else if(section == 2)
        return section2View;
        
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 0){
        return section0View.frame.size.height;
    }else if(section == 1){
        return section1View.frame.size.height;
    }else if(section == 2){
        return 65;
    }
    
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellupdateprofile"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cellupdateprofile"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.font = [UIFont systemFontOfSize:14.];
    cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.textLabel.shadowColor = [UIColor whiteColor];
    cell.textLabel.shadowOffset = CGSizeMake(0, 1);
    
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14.];
    cell.detailTextLabel.textColor = [UIColor grayColor];
    cell.detailTextLabel.shadowColor = [UIColor whiteColor];
    cell.detailTextLabel.shadowOffset = CGSizeMake(0, 1);
    
    if(indexPath.row == 0){
        cell.textLabel.text = @"Change Password";
    }else{
        cell.textLabel.text = @"Birthday";
        cell.detailTextLabel.text = [data valueForKey:@"birthday"];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.row == 0){
        SMChangePasswordPage *change = [[[SMChangePasswordPage alloc] init] autorelease];
        [self.navigationController pushViewController:change animated:YES];
    }else{
        SMSelectDatePage *date = [[[SMSelectDatePage alloc] init] autorelease];
        date.delegate = self;
        [self.navigationController pushViewController:date animated:YES];
        if(selectedDate)
            [date setDate:selectedDate];
    }
}

#pragma mark - delegate select date
-(void)SMSelectDatePage:(SMSelectDatePage *)page didSelectDate:(NSDate *)date{
    NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
    [format setDateFormat:@"dd MMMM yyyy"];
    NSString *birth = [format stringFromDate:date];
    [data setValue:birth forKey:@"birthday"];
    [mainTable reloadData];
    
    if(selectedDate){
        [selectedDate release];
    }
    
    selectedDate = [date retain];
}

#pragma mark - delegate ASI
-(void)requestFailed:(ASIHTTPRequest *)request{
    requestCount--;
    [queue cancelAllOperations];
    [loading hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to contact server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)requestStarted:(ASIHTTPRequest *)request{
    if(!loading){
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
    }
    
    if(request.tag == 1){
        loading.labelText = @"Updating Profile...";
    }else{
        loading.labelText = @"Uploading image...";
    }
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSDictionary *dict = [[request responseString] JSONValue];
    
    if([[dict valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        if(request.tag == 1){
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
            [profile load];
            profile.fullname = displayName.text;
            profile.birthday = selectedDate;
            profile.gender = male.selected?@"pria":@"wanita";
            profile.status = personalMessage.text;
            [profile save];
            
//            if(personalMessage.text.length > 0){
                SMMyUserProfile *_profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
                [_profile load];
                [_profile broadcast:BroadcastTypeStatus];
//            }
        }else{
            NSString *avatar = [dict valueForKey:@"AVATAR_URL"];
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
            [profile load];
            profile.avatar = avatar;
            profile.avatarThumb = avatar;
            [profile save];
            
            [[EGOCache currentCache] removeCacheForKey:keyForURL([NSURL URLWithString:avatar], nil)];
            
            SMMyUserProfile *_profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
            [_profile load];
            [_profile broadcast:BroadcastTypeAvatar];
        }
    }
    
    requestCount--;
    if(requestCount <= 0){
        [loading hide:YES];
        [self updateMyvCard];
        
        [self refreshView];
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
        [leftMenu reloadTableView];
        
        [self back:nil];
    }
}

#pragma mark - delegate HUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
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

-(void)updateMyvCard{
    XMPPvCardTemp *myvCard = [[SMXMPPHandler XMPPHandler] myvCardTemp];
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    
    myvCard.bday = profile.birthday;
    myvCard.emailAddresses = [NSArray arrayWithObjects:profile.email, nil];
    
    NSArray *namesArray = [profile.fullname componentsSeparatedByString:@" "];
    
    myvCard.nickname = [namesArray objectAtIndex:0];
    myvCard.givenName = [namesArray objectAtIndex:0];
    if(namesArray.count > 2){
        myvCard.middleName = [namesArray objectAtIndex:1];
        myvCard.familyName = [namesArray lastObject];
    }else if(namesArray.count > 1){
        myvCard.familyName = [namesArray lastObject];
        myvCard.middleName = @"";
    }
    
    myvCard.photo = UIImageJPEGRepresentation(editedImage, 0.7);
    
    [[SMXMPPHandler XMPPHandler] updateMyvCardTemp:myvCard];
    [[SMXMPPHandler XMPPHandler] sendStatusBroadcast:profile.status];
}

#pragma mark - delegate ImagePicker
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
    imageIsChanged = YES;
    
    if(editedImage)
        [editedImage release];
    if(originalImage)
        [originalImage release];
    
    editedImage = [[info valueForKey:@"UIImagePickerControllerEditedImage"] retain];
    originalImage = [[info valueForKey:@"UIImagePickerControllerOriginalImage"] retain];
    
    if (editedImage) {
        foto.image = editedImage;
    } else {
        foto.image = originalImage;
    }
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
