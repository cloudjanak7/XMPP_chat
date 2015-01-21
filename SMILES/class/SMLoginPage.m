//
//  SMLoginPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMLoginPage.h"
#import "SMXMPPHandler.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMContactListPage.h"
#import "MBProgressHUD.h"
#import "SMLeftMenuPage.h"
#import "SMPersistentObject.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "JSON.h"
#import "SMMyUserProfile.h"

@interface SMLoginPage ()<SMXMPPHandlerDelegate, UITextFieldDelegate, MBProgressHUDDelegate, ASIHTTPRequestDelegate, UIAlertViewDelegate>{
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *passwordField;
    IBOutlet UIView *containeView;
    IBOutlet UIButton *backButton;
    
    MBProgressHUD *loading;
}

-(IBAction)login:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(IBAction)back:(id)sender;
-(IBAction)forgotPassword:(id)sender;

@end                                                                                                                                                                                                                                                           

@implementation SMLoginPage

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    usernameField.delegate = self;
    passwordField.delegate = self;
    [super viewDidLoad];
    
    usernameField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
    passwordField.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    containeView.tag = containeView.frame.origin.y;
}

-(void)viewDidUnload{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - penanganan keyboard
-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGRect keyboardRect = [[userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDelay:0.2];
    CGRect frame = containeView.frame;
    frame.origin.y = keyboardRect.origin.y - frame.size.height - 20;
    containeView.frame = frame;
    [UIView commitAnimations];
}

-(void)keyboardDidHide:(id)info{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDelay:0.2];
    CGRect frame = containeView.frame;
    frame.origin.y = containeView.tag;
    containeView.frame = frame;
    [UIView commitAnimations];
}

#pragma mark - Action
-(void)login:(id)sender{
    [self hideKeyboard:nil];
    if(usernameField.text.length < 1 || passwordField.text.length < 1){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Cannot login with empty user or password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    NSUserDefaults *setting = [NSUserDefaults standardUserDefaults];
    [setting setValue:usernameField.text forKey:@"username"];
    [setting setValue:passwordField.text forKey:@"password"];
    [setting setValue:[NSNumber numberWithBool:YES] forKey:@"autosignin"];
    
    loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
    loading.delegate = self;
    loading.labelText = nil;
    
    [self loginToAPI];
}

-(void)loginToAPI{
    SMAppConfig *config = [SMAppConfig sharedConfig];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogin]];
    [request setPostValue:usernameField.text forKey:@"username"];
    [request setPostValue:passwordField.text forKey:@"password"];
    [request setPostValue:config.deviceToken forKey:@"regid"];
    [request setPostValue:config.deviceIMEI forKey:@"imei"];
    [request setPostValue:config.carrier forKey:@"carrier"];
    [request setPostValue:config.longitudeStr forKey:@"long"];
    [request setPostValue:config.latitudeStr forKey:@"lat"];
    
    request.delegate = self;
    [request startAsynchronous];
}

-(void)hideKeyboard:(id)sender{
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)forgotPassword:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Forgot Password" message:@"Dou you want to reset your password?" delegate:self cancelButtonTitle:@"No, I Remember" otherButtonTitles:@"Yes, Reset It", nil];
    alert.tag = 1;
    [alert show];
}

#pragma mark - alert delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 1){
        if(buttonIndex == 1){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Insert your username" message:@"\n\n" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
            alert.tag = 2;
            UITextField *text = [[[UITextField alloc] initWithFrame:CGRectMake((alertView.frame.size.width-240)*0.5, 55, 240, 30)] autorelease];
            text.borderStyle = UITextBorderStyleRoundedRect;
            text.placeholder = @"Username...";
            [alert addSubview:text];
            [alert show];
        }
    }else if(alertView.tag == 2){
        if(buttonIndex == 1){
            UITextField *text = nil;
            for(id one in alertView.subviews){
                if([one isKindOfClass:[UITextField class]]){
                    text = one;
                }
            }
            NSString *username = [text text];
            
            if(username.length < 1){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Canceled" message:@"Cannot reset password for blank username." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }else{
                loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
                loading.mode = MBProgressHUDModeIndeterminate;
                loading.delegate = self;
                loading.labelText = @"Resetting Password...";
                
                ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLResetPassword]];
                [request setPostValue:usernameField.text forKey:@"username"];
                request.delegate = self;
                request.tag = 2;
                [request startAsynchronous];
            }
        }
    }
    [alertView release];
}

#pragma mark - delegate ASI HTTP
-(void)requestFailed:(ASIHTTPRequest *)request{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Your Internet Connection." message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    [loading hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSDictionary *reply = [[request responseString] JSONValue];
    
    if([[reply valueForKey:@"ALREADY_LOGGEDIN"] isEqualToString:@"Y"])
    {
        [loading hide:YES];

//        [[[UIAlertView alloc] initWithTitle:@"Warning." message:@"you are login on other device." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
        loading.labelText = nil;

        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogout]];
        [request setPostValue:usernameField.text forKey:@"username"];
        request.tag = 3;
        request.delegate = self;
        [request startAsynchronous];

        return;
    }
    
    if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        if(request.tag == 2){
            [loading hide:YES];
            NSString *message = [reply valueForKey:@"MESSAGE"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
        } else if (request.tag == 3) {
            [loading hide:YES];
            [self login:nil];
        }else{
            SMXMPPHandler *handler = [SMXMPPHandler XMPPHandler];
            [handler addXMPPHandlerDelegate:self];
            [handler connect];
            
            NSString *username = [reply valueForKey:@"USERNAME"];
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:username];
            [profile load];
            profile.admin = [[reply valueForKey:@"IS_ADMIN"] boolValue];
            profile.fullname = [reply valueForKey:@"FULLNAME"];
            [profile save];
        }
    }else{
        [loading hide:YES];
        NSString *message = [reply valueForKey:@"MESSAGE"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - SMXMPP handler delegate

-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
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

#pragma mark - textField delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == usernameField){
        [passwordField becomeFirstResponder];
    }else{
        [self hideKeyboard:nil];
    }
    return NO;
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

@end
