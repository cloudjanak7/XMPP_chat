//
//  SMProfileRegPage.m
//  SMILES
//
//  Created by asepmoels on 7/9/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMProfileRegPage.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "MBProgressHUD.h"
#import "JSON.h"
#import "SMXMPPHandler.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMContactListPage.h"
#import "SMMyUserProfile.h"
#import "SMLeftMenuPage.h"
#import "SMPersistentObject.h"

@interface SMProfileRegPage () <SMXMPPHandlerDelegate, UIActionSheetDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate>{
    IBOutlet UIView *contentView;
    IBOutlet UITextField *email;
    IBOutlet UITextField *password;
    IBOutlet UITextField *confirmPassword;
    IBOutlet UIButton *genderOption;
    IBOutlet UITextField *username;
    IBOutlet UIScrollView *scrollView;
    
    CGRect originalScrollViewFrame;
    NSInteger selectedGender;
    MBProgressHUD *loading;
}

-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)toggleSecurePassword:(id)sender;
-(IBAction)selectGender:(id)sender;
-(IBAction)submit:(id)sender;

@end

@implementation SMProfileRegPage

@synthesize phoneNumber, country;

- (void)dealloc
{
    [phoneNumber release];
    [country release];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [scrollView addSubview:contentView];
    scrollView.contentSize = contentView.frame.size;
   
    selectedGender = -1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    originalScrollViewFrame = scrollView.frame;
}

-(void)viewDidUnload{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

#pragma mark - penanganan keyboard
-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGRect keyboardRect = [[userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    CGRect frame = scrollView.frame;
    frame.size.height = keyboardRect.origin.y - frame.origin.y - 20;
    scrollView.frame = frame;
}

-(void)keyboardDidHide:(id)info{
    scrollView.frame = originalScrollViewFrame;
}

#pragma mark - Action

-(void)toggleSecurePassword:(UIButton *)sender{
    [self hideKeyboard:nil];
    sender.selected = !sender.selected;
    
    if(sender.selected){
        password.secureTextEntry = NO;
        confirmPassword.secureTextEntry = NO;
    }else{
        password.secureTextEntry = YES;
        confirmPassword.secureTextEntry = YES;
    }
}

-(void)selectGender:(id)sender{
    [self hideKeyboard:nil];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Male", @"Female", nil];
    [sheet showInView:self.view];
    sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    [username resignFirstResponder];
    [email resignFirstResponder];
    [password resignFirstResponder];
    [confirmPassword resignFirstResponder];
}

-(void)alert:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)submit:(id)sender{
    [self hideKeyboard:nil];
    if(username.text.length < 1){
        [self alert:@"Please input username."];
        return;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[A-Za-z]+[A-Z0-9a-z_]+"];
    if(![predicate evaluateWithObject:[username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]]){
        [self alert:@"Username must be started with alphabet and only allowed to use alphanumeric and underscore (_)."];
        return;
    }
    predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"];
    if(![predicate evaluateWithObject:email.text]){
        [self alert:@"Please insert the valid email address."];
        return;
    }
    if(selectedGender < 0){
        [self alert:@"Select your gender."];
        return;
    }
    if(password.text.length < 1){
        [self alert:@"Please fill the password field."];
        return;
    } else if (password.text.length < 8) {
        [self alert:@"The length of password should be over 8."];
        return;
    }
    
    if(confirmPassword.text.length < 1){
        [self alert:@"Please fill the confirm password field."];
        return;
    }
    if(![password.text isEqualToString:confirmPassword.text]){
        [self alert:@"Confirm password doesn't match."];
        return;
    }
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLRegister]];
    request.delegate = self;
    [request setPostValue:email.text forKey:@"email"];
    [request setPostValue:username.text forKey:@"username"];
    [request setPostValue:username.text forKey:@"fullname"];
    [request setPostValue:password.text forKey:@"password"];
    [request setPostValue:[SMAppConfig sharedConfig].deviceToken forKey:@"regid"];
    [request setPostValue:[SMAppConfig sharedConfig].deviceIMEI forKey:@"imei"];
    [request setPostValue:self.phoneNumber forKey:@"phone"];
    [request setPostValue:self.country forKey:@"country"];
    [request setPostValue:selectedGender==0?@"pria":@"wanita" forKey:@"gender"];
    [request setTag:10];
    [request startAsynchronous];
}

#pragma mark - delegate ActionSheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    selectedGender = buttonIndex;
    [genderOption setTitle:[actionSheet buttonTitleAtIndex:selectedGender] forState:UIControlStateNormal];
    [actionSheet release];
}

#pragma mark - delegate ASIHTTP
-(void)requestStarted:(ASIHTTPRequest *)request{
    if (request.tag == 10) {
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.mode = MBProgressHUDModeIndeterminate;
        loading.delegate = self;
        loading.labelText = @"Registering..";
    } else
        loading.labelText = nil;
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Your Internet Connection." message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
    [loading hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSDictionary *response = [[request responseString] JSONValue];

    NSString *status = [[response valueForKey:@"STATUS"] uppercaseString];
    if([status isEqualToString:@"SUCCESS"]){
        if (request.tag == 10) {
            [loading hide:YES];
            [[NSUserDefaults standardUserDefaults] setValue:username.text forKey:@"username"];
            [[NSUserDefaults standardUserDefaults] setValue:password.text forKey:@"password"];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"autosignin"];
            
            NSArray *viewControllers = self.navigationController.viewControllers;
            UIViewController *target = [viewControllers objectAtIndex:1];
            [self.navigationController popToViewController:target animated:YES];
        } else {
            SMXMPPHandler *handler = [SMXMPPHandler XMPPHandler];
            [handler addXMPPHandlerDelegate:self];
            [handler connect];
            
            NSString *sUsername = [response valueForKey:@"USERNAME"];
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:sUsername];
            [profile load];
            profile.admin = [[response valueForKey:@"IS_ADMIN"] boolValue];
            profile.fullname = [response valueForKey:@"FULLNAME"];
            [profile save];
        }
    }else{
        NSString *msg = [[response valueForKey:@"MESSAGE"] lowercaseString];
        if ([msg isEqualToString:@"username already taken"]) {
            [self loginToAPI];
        } else {
            [loading hide:YES];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:[response valueForKey:@"MESSAGE"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }
}

#pragma mark - Login
-(void)loginToAPI{
    
    NSUserDefaults *setting = [NSUserDefaults standardUserDefaults];
    [setting setValue:username.text forKey:@"username"];
    [setting setValue:password.text forKey:@"password"];
    [setting setValue:[NSNumber numberWithBool:YES] forKey:@"autosignin"];
    
    SMAppConfig *config = [SMAppConfig sharedConfig];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogin]];
    [request setPostValue:username.text forKey:@"username"];
    [request setPostValue:password.text forKey:@"password"];
    [request setPostValue:config.deviceToken forKey:@"regid"];
    [request setPostValue:config.deviceIMEI forKey:@"imei"];
    [request setPostValue:config.carrier forKey:@"carrier"];
    [request setPostValue:config.longitudeStr forKey:@"long"];
    [request setPostValue:config.latitudeStr forKey:@"lat"];
    [request setTag:20];
    request.delegate = self;
    [request startAsynchronous];
}

#pragma mark - SMXMPP handler delegate
- (void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info
{
    if(type == XMPPHandlerExecuteTypeLogin){
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        [handler addXMPPHandlerDelegate:(SMContactListPage*)delegate.mainViewController.centerController];
        [handler addXMPPHandlerDelegate:(SMLeftMenuPage*)delegate.mainViewController.leftController];
        [self.navigationController pushViewController:(UIViewController *)delegate.mainViewController animated:YES];
        
        [[SMPersistentObject sharedObject] collectAdressBookDataForUser:[SMXMPPHandler XMPPHandler].myJID.user];
    }else if(type == XMPPHandlerExecuteTypeLoginFailed){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Wrong username/password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        [handler removeXMPPHandlerDelegate:self];
    }else if(type == XMPPHandlerExecuteTypeDisconnect){
        NSError *error = [info valueForKey:@"info"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connecting Failed" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
    [loading hide:YES];
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

@end
