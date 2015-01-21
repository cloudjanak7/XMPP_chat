//
//  SMLandingPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMLandingPage.h"
#import "SMLoginPage.h"
#import "SMRegisterPage.h"
#import "SMXMPPHandler.h"
#import "MBProgressHUD.h"
#import "SMAppDelegate.h"
#import "SMContactListPage.h"
#import "IIViewDeckController.h"
#import "SMLeftMenuPage.h"
#import "SMPersistentObject.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "SMMyUserProfile.h"
#import "JSON.h"

@interface SMLandingPage () <SMXMPPHandlerDelegate, MBProgressHUDDelegate, ASIHTTPRequestDelegate>{
    MBProgressHUD *loading;
}

-(IBAction)registerPage:(id)sender;
-(IBAction)loginPage:(id)sender;

@end

@implementation SMLandingPage

@synthesize bConnectFailed;

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
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (bConnectFailed) {
        return;
    }
    
    BOOL autosignin = [[[NSUserDefaults standardUserDefaults] valueForKey:@"autosignin"] boolValue];
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    if(autosignin && username.length > 0 && password.length > 0){
        [self loginToAPI];
        
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
        loading.labelText = nil;
    }
    
}

-(void)loginToAPI{
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    SMAppConfig *config = [SMAppConfig sharedConfig];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogin]];
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:password forKey:@"password"];
    [request setPostValue:config.deviceToken forKey:@"regid"];
    [request setPostValue:config.deviceIMEI forKey:@"imei"];
    [request setPostValue:config.carrier forKey:@"carrier"];
    [request setPostValue:config.longitudeStr forKey:@"long"];
    [request setPostValue:config.latitudeStr forKey:@"lat"];
    
    request.delegate = self;
    [request startAsynchronous];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    
    
    if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        SMXMPPHandler *handler = [SMXMPPHandler XMPPHandler];
        [handler addXMPPHandlerDelegate:self];
        [handler connect];
        
        NSString *username = [reply valueForKey:@"USERNAME"];
        SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:username];
        [profile load];
        profile.admin = [[reply valueForKey:@"IS_ADMIN"] boolValue];
        profile.fullname = [reply valueForKey:@"FULLNAME"];
        [profile save];
    }else{
        [loading hide:YES];
        NSString *message = [reply valueForKey:@"MESSAGE"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - Action
-(void)registerPage:(id)sender{
    SMRegisterPage *registerpage = [[SMRegisterPage alloc] init];
    [self.navigationController pushViewController:registerpage animated:YES];
    [registerpage release];
}

-(void)loginPage:(id)sender{
    SMLoginPage *login = [[SMLoginPage alloc] init];
    [self.navigationController pushViewController:login animated:YES];
    [login release];
}

#pragma mark - delegate XMPPHandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    [loading hide:YES];
    [handler removeXMPPHandlerDelegate:self];
    
    if(type == XMPPHandlerExecuteTypeLogin){
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        
        [handler addXMPPHandlerDelegate:(SMContactListPage*)delegate.mainViewController.centerController];
        [handler addXMPPHandlerDelegate:(SMLeftMenuPage*)delegate.mainViewController.leftController];
        
        [self.navigationController pushViewController:(UIViewController *)delegate.mainViewController animated:YES];
        
        [[SMPersistentObject sharedObject] collectAdressBookDataForUser:[SMXMPPHandler XMPPHandler].myJID.user];
    }else if(type == XMPPHandlerExecuteTypeLoginFailed){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Check Your Username and Password. Please Login Manualy" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }else if(type == XMPPHandlerExecuteTypeDisconnect){
        NSError *error = [info valueForKey:@"info"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connecting Failed" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

@end
