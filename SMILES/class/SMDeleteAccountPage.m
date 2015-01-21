//
//  SMDeleteAccountPage.m
//  SMILES
//
//  Created by asepmoels on 8/2/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMDeleteAccountPage.h"
#import "MBProgressHUD.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "SMXMPPHandler.h"
#import "JSON.h"

@interface SMDeleteAccountPage ()<MBProgressHUDDelegate>{
    MBProgressHUD *loading;
}

-(IBAction)back:(id)sender;
-(IBAction)deleteAccount:(id)sender;

@end

@implementation SMDeleteAccountPage

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)deleteAccount:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure to delete your Account?" delegate:self cancelButtonTitle:@"No, don't delete" otherButtonTitles:@"Yes, Delete It", nil];
    [alert show];
}


#pragma mark - delegate alertview
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [alertView release];
    if(buttonIndex == 1){
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
        loading.labelText = @"Deleting Account";
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserDelete]];
        [request setPostValue:[SMXMPPHandler XMPPHandler].myJID.user forKey:@"username"];
        request.delegate = self;
        [request startAsynchronous];
    }
}

#pragma mark - ASIHTTP
-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [loading hide:YES];
    NSDictionary *response = [[request responseString] JSONValue];
    if([[response valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        [[SMXMPPHandler XMPPHandler] forceLogout];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to delete your account." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - delegate HUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
}

@end
