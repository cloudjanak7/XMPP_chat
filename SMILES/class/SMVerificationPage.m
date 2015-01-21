//
//  SMVerificationPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMVerificationPage.h"
#import "ASIFormDataRequest.h"
#import "ASIHTTPRequest.h"
#import "SMAppConfig.h"
#import "JSON.h"
#import "SMProfileRegPage.h"

@interface SMVerificationPage () <ASIHTTPRequestDelegate>{
    NSString *validCode;
    NSTimer *timer;
    NSInteger counter;
    
    IBOutlet UIButton *resendButton;
    IBOutlet UILabel *messageLabel;
    IBOutlet UILabel *timerLabel;
    IBOutlet UITextField *verifyCode;
}

-(IBAction)verify:(id)sender;
-(IBAction)resend:(id)sender;
-(IBAction)back:(id)sender;
-(IBAction)hideKeyboard:(id)sender;

@end

@implementation SMVerificationPage

@synthesize phoneNumber, country;

- (void)dealloc
{
    [validCode release];
    [phoneNumber release];
    [country release];
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
    
    messageLabel.text = [NSString stringWithFormat:@"Please enter the Verification Code sent via SMS to %@", self.phoneNumber];
    
    [self sendRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Action
-(void)sendRequest{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLVerifyCode]];
    [request setPostValue:[self.phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""] forKey:@"phone"];
    request.delegate = self;
    [request startAsynchronous];
    
    resendButton.enabled = NO;
    counter = 30;
    if(timer)
        [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

-(void)tick{
    timerLabel.text = [NSString stringWithFormat:@"Retry (time) %lds", (long)counter];
    
    if(counter <= 0){
        [timer invalidate];
        timer = nil;
        resendButton.enabled = YES;
    }
    counter--;
}

-(void)resend:(id)sender{
    [self sendRequest];
}

-(void)verify:(id)sender{
    if([validCode isEqualToString:verifyCode.text]){
        if(timer){
            [timer invalidate];
            timer = nil;
        }
        
        [verifyCode resignFirstResponder];
        
        SMProfileRegPage *reg = [[SMProfileRegPage alloc] init];
        reg.phoneNumber = self.phoneNumber;
        reg.country = self.country;
        [self.navigationController pushViewController:reg animated:YES];
        [reg release];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Insert The Valid Code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)hideKeyboard:(id)sender{
    [verifyCode resignFirstResponder];
}

#pragma mark - delegate ASIHTTP
-(void)requestFinished:(ASIHTTPRequest *)request{

    NSDictionary *response = [[request responseString] JSONValue];
    NSString *status = [response valueForKey:@"STATUS"];
    if([[status uppercaseString] isEqualToString:@"SUCCESS"]){
        if(validCode){
            [validCode release];
        }
        
        validCode = [[[response valueForKey:@"CODE"] stringValue] copy];
    }else{
        NSString *message = [response valueForKey:@"MESSAGE"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end
