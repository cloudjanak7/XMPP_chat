//
//  SMSplashScreen.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMSplashScreen.h"
#import "SMAppConfig.h"
#import "ASIHTTPRequest.h"
#import "JSON.h"

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


@interface SMSplashScreen () <ASIHTTPRequestDelegate,SMXMPPHandlerDelegate, MBProgressHUDDelegate, ASIHTTPRequestDelegate, UIAlertViewDelegate>{
    NSTimer *timer;
    BOOL configurationLoaded;
    
    MBProgressHUD *loading;
    
    BOOL autoLoginStatus;
}

@end

@implementation SMSplashScreen

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
    shouldCheckConnection = YES;
    
    BOOL autosignin = [[[NSUserDefaults standardUserDefaults] valueForKey:@"autosignin"] boolValue];
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    if(autosignin && username.length > 0 && password.length > 0){
        return;
    }
    else
    {
        SMLandingPage *landing = [[SMLandingPage alloc] init];
        [self.navigationController pushViewController:landing animated:YES];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    autoLoginStatus = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(BOOL)shouldCheckConnection{
    return shouldCheckConnection;
}

-(void)checkConnection{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:kURLConfiguration]];
    [request setDelegate:self];
    [request startAsynchronous];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:2. target:self selector:@selector(timerFinished) userInfo:nil repeats:NO];
}

-(void)timerFinished{
    if(timer){
        [timer invalidate];
        timer = nil;
    }
    
    if(!configurationLoaded){
        timer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(timerFinished) userInfo:nil repeats:NO];
    }else{
        [self nextPage];
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
    autoLoginStatus = YES;

    [request startAsynchronous];
}

- (void)nextPage {
    
    shouldCheckConnection = NO;
    
    BOOL autosignin = [[[NSUserDefaults standardUserDefaults] valueForKey:@"autosignin"] boolValue];
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    if(autosignin && username.length > 0 && password.length > 0){
        [self loginToAPI];
        
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
        loading.labelText = nil;
    }
    else
    {
        SMLandingPage *landing = [[SMLandingPage alloc] init];
        [self.navigationController pushViewController:landing animated:YES];
    }
}

#pragma mark - Delegate ASIHTTP
-(void)requestFailed:(ASIHTTPRequest *)request{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Check Your Internet Connection." message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    configurationLoaded = YES;
    
    if(!autoLoginStatus)
    {
        NSDictionary *root = [[request responseString] JSONValue];
        
        if([[root valueForKey:@"forceupdate"] boolValue]){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Your SMILES version is out of date. Please update to the new version." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        
        NSDictionary *version = [root valueForKey:@"version"];
        NSString *ios = [version valueForKey:@"ios"];
        NSUserDefaults *setting = [NSUserDefaults standardUserDefaults];
        [setting setValue:ios forKey:@"version"];
    }
    else
    {
        autoLoginStatus = NO;
        
        NSDictionary *reply = [[request responseString] JSONValue];
        
        if([[reply valueForKey:@"ALREADY_LOGGEDIN"] isEqualToString:@"Y"])
        {
            [loading hide:YES];
            autoLoginStatus = YES;

            loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
            loading.delegate = self;
            loading.labelText = nil;
            
            ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogout]];
            NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"username"];
            [request setPostValue:username forKey:@"username"];
            request.tag = 3;
            request.delegate = self;
            [request startAsynchronous];
            
            return;
        }
        
        if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
            if (request.tag == 3) {
                [loading hide:YES];
                [self nextPage];
            } else {
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
    
        SMLandingPage *landing = [[SMLandingPage alloc] init];
        [self.navigationController pushViewController:landing animated:YES];

    }else if(type == XMPPHandlerExecuteTypeDisconnect){
        NSError *error = [info valueForKey:@"info"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connecting Failed" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        alert.tag = 1;
        [alert release];
    }
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        SMLandingPage *landing = [[SMLandingPage alloc] init];
        landing.bConnectFailed = YES;
        [self.navigationController pushViewController:landing animated:YES];
    }
}

@end
