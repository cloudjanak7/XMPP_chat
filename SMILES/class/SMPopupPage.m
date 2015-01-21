//
//  SMPopupPage.m
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMPopupPage.h"
#import "SMAppDelegate.h"

@interface SMPopupPage ()<UITextFieldDelegate>{
    IBOutlet UIView *inviteFromContactsView;
    IBOutlet UIView *inviteGroupView;
    IBOutlet UILabel *inviteTitleLabel;
    IBOutlet UILabel *inviteGroupMessage;
    IBOutlet UITextField *messageBroadcast;
    IBOutlet UIView *adminBroadcastView;
    
    BOOL needReleased;
    SMPopupType myCurrentType;
}

-(IBAction)hideMe:(id)sender;
-(IBAction)optionSelected:(id)sender;
-(IBAction)hideKeyboard:(id)sender;

@end

@implementation SMPopupPage

@synthesize delegate, userInfo, tag, message;

- (void)dealloc
{
    [userInfo release];
    [message release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

-(id)initWithType:(SMPopupType)type{
    self = [super init];
    if(self){
        myCurrentType = type;
        needReleased = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)keyboardDidShow:(NSDictionary *)info{
    NSDictionary *userinfo = [info valueForKey:@"userInfo"];

    CGRect rect = [[userinfo valueForKey:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    CGFloat duration = [[userinfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    UIView *currentView = [self.view.subviews objectAtIndex:0];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = currentView.frame;
    frame.origin.y = self.view.frame.size.height - rect.size.height - frame.size.height;
    currentView.frame = frame;
    [UIView commitAnimations];
}

-(void)keyboardDidHide:(NSDictionary *)info{
    NSDictionary *userinfo = [info valueForKey:@"userInfo"];
    CGFloat duration = [[userinfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    
    UIView *currentView = [self.view.subviews objectAtIndex:0];
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = currentView.bounds;
    frame.origin.y = 0.5 * (self.view.frame.size.height - frame.size.height);
    currentView.frame = frame;
    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)setBackgroundToModal{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:.5];
    self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:0.7];
    [UIView commitAnimations];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(myCurrentType == SMPopupTypeInviteFriend || myCurrentType == SMPopupTypeInviteOther){
        CGRect frame = inviteFromContactsView.bounds;
        frame.origin.y = 0.5 * (self.view.frame.size.height - frame.size.height);
        inviteFromContactsView.frame = frame;
        if(myCurrentType == SMPopupTypeInviteOther)
            inviteTitleLabel.text = @"Invite";
        
        [self.view addSubview:inviteFromContactsView];
    }else if(myCurrentType == SMPopupTypeInviteGroup){
        CGRect frame = inviteGroupView.bounds;
        frame.origin.y = 0.5 * (self.view.frame.size.height - frame.size.height);
        inviteGroupView.frame = frame;
        
        [self.view addSubview:inviteGroupView];
    }else if(myCurrentType == SMPopupTypeAdminBroadcast){
        CGRect frame = adminBroadcastView.bounds;
        frame.origin.y = 0.5 * (self.view.frame.size.height - frame.size.height);
        adminBroadcastView.frame = frame;
        
        [self.view addSubview:adminBroadcastView];
    }
    
    [self setAllMessage];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)setAllMessage{
    inviteGroupMessage.text = self.message;
}

-(void)show{
    SMAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate.window addSubview:self.view];
    self.view.frame = appDelegate.window.bounds;
    
    CGRect frame = self.view.frame;
    frame.origin.y = appDelegate.window.frame.size.height;
    self.view.frame = frame;
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(setBackgroundToModal)];
    frame.origin.y = 0;
    self.view.frame = frame;
    [UIView commitAnimations];
}

-(void)hide{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeView)];
    self.view.backgroundColor = [UIColor clearColor];
    [UIView commitAnimations];
}

-(void)removeView{
    CGRect frame = self.view.frame;
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(clearMe)];
    frame.origin.y = frame.size.height;
    self.view.frame = frame;
    [UIView commitAnimations];
}

-(void)clearMe{
    [self.view removeFromSuperview];
    if(needReleased)
        [self release];
}

#pragma mark - Action
-(void)hideMe:(id)sender{
    [self hide];
}

-(void)optionSelected:(UIButton *)sender{
    NSDictionary *info = nil;
    
    if(myCurrentType == SMPopupTypeAdminBroadcast){
        info = [NSDictionary dictionaryWithObject:messageBroadcast.text forKey:@"message"];
        
        if(sender.tag == 1 && messageBroadcast.text.length < 1){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Can not send blank message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
    }
    
    if(self.delegate){
        needReleased = NO;
        [self hide];
        [self.delegate smpopupView:self didSelectItemAtIndex:sender.tag info:info];
    }
}

-(void)hideKeyboard:(id)sender{
    [messageBroadcast resignFirstResponder];
}

#pragma mark - delegate textfield
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 1;
    [self optionSelected:btn];
    return YES;
}

@end
