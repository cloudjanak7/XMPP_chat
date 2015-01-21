//
//  SMChangePasswordPage.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChangePasswordPage.h"
#import "MBProgressHUD.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "JSON.h"
#import "SMXMPPHandler.h"

@interface SMChangePasswordPage () <MBProgressHUDDelegate, ASIHTTPRequestDelegate, UIAlertViewDelegate> {
    IBOutlet UIScrollView *scroll;
    IBOutlet UITextField *oldPassword;
    IBOutlet UITextField *newPassword;
    IBOutlet UITextField *confirmNewPassword;
    
    MBProgressHUD *loading;
}

-(IBAction)back:(id)sender;
-(IBAction)changePassword:(id)sender;

@end

@implementation SMChangePasswordPage

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    scroll.contentSize = CGSizeMake(320, 230);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - ACtion
-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];

    CGRect rect = [[userInfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = scroll.frame;
    frame.size.height = self.view.frame.size.height - rect.size.height - frame.origin.y;
    scroll.frame = frame;
    [UIView commitAnimations];
}

-(void)keyboardDidHide:(NSDictionary *)info{
    NSDictionary *userInfo = [info valueForKey:@"userInfo"];
    CGFloat duration = [[userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = scroll.frame;
    frame.size.height = self.view.frame.size.height - frame.origin.y;
    scroll.frame = frame;
    [UIView commitAnimations];
}

-(void)back:(id)sender{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)alert:(NSString *)message{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)changePassword:(id)sender{
    /*if(oldPassword.text.length < 1){
        [self alert:@"Current Password must be filled."];
        return;
    }*/
    if(!(newPassword.text.length >= 6 && newPassword.text.length <= 20) || !(confirmNewPassword.text.length >=6 && confirmNewPassword.text.length <= 20)){
        [self alert:@"New Password and Confirm New Password must be 6-20 length."];
        return;
    }
    if(![newPassword.text isEqualToString:confirmNewPassword.text]){
        [self alert:@"New Password and Confirm New Password doesn't match"];
        return;
    }
    
    NSString *oldPasswd = [[NSUserDefaults standardUserDefaults] valueForKey:@"password"];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLChangePassword]];
    [request setPostValue:[SMXMPPHandler XMPPHandler].myJID.user forKey:@"username"];
    [request setPostValue:oldPasswd forKey:@"current_password"];
    [request setPostValue:newPassword.text forKey:@"new_password1"];
    [request setPostValue:confirmNewPassword.text forKey:@"new_password2"];
    request.delegate = self;
    [request startAsynchronous];
}

#pragma mark - delegate asi
-(void)requestStarted:(ASIHTTPRequest *)request{
    loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
    loading.labelText = @"Changing password.";
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to contact server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [loading hide:YES];
    NSDictionary *dict = [[request responseString] JSONValue];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[dict valueForKey:@"MESSAGE"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    if([[dict valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        alert.tag = 1;
        
        [[NSUserDefaults standardUserDefaults] setValue:newPassword.text forKey:@"password"];
    }
    alert.delegate = self;
    [alert show];
}

#pragma mark - delegate ui alert
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    NSInteger tag = alertView.tag;
    [alertView release];
    
    if(tag == 1){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - delegate hud
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
}

@end
