//
//  SMAboutPage.m
//  SMILES
//
//  Created by asepmoels on 7/25/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMAboutPage.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "MBProgressHUD.h"
#import "JSON.h"

@interface SMAboutPage () <ASIHTTPRequestDelegate, MBProgressHUDDelegate, UIWebViewDelegate>{
    IBOutlet UIWebView *webView;
    IBOutlet UILabel *titleLabel;
    IBOutlet UILabel *versionLabel;
    IBOutlet UIView *aboutSubView;
    
    MBProgressHUD *loading;
}

-(IBAction)back:(id)sender;

@end

@implementation SMAboutPage

@synthesize pageType;

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
    
    if(self.pageType == PageTypeAbout){
        titleLabel.text= @"About";
        /*
        aboutSubView.frame = self.view.frame;
        [self.view insertSubview:aboutSubView aboveSubview:webView];
        
        NSUserDefaults *setting = [NSUserDefaults standardUserDefaults];
        versionLabel.text = [setting valueForKey:@"version"];
        
        return;*/
    }else if(self.pageType == PageTypePrivacy){
        titleLabel.text= @"Privacy Policy";
    }else if(self.pageType == PageTypeToS){
        titleLabel.text= @"Terms of Services";
    }
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLGetText]];
    NSInteger pageId = 7;
    if(self.pageType == PageTypeToS)
        pageId = 6;
    else if(self.pageType == PageTypeAbout)
        pageId = 8;
    
    
    [request setPostValue:[NSNumber numberWithInt:(int)pageId] forKey:@"id"];
    request.delegate = self;
    [request startAsynchronous];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - delegate ASIHttp
-(void)requestStarted:(ASIHTTPRequest *)request{
    if(!loading){
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
        loading.labelText = @"Loading...";
    }
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSDictionary *dict = [[request responseString] JSONValue];
    NSString *content = [dict valueForKey:@"CONTENT"];
    content = [content stringByAppendingString:@"<style type=\"text/css\">body{margin:15px;margin-top:30px;}</style>"];
    [webView loadHTMLString:content baseURL:request.url.baseURL];
    webView.delegate = self;
}

-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
}

#pragma mark - delegate webview
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [loading hide:YES];
}

@end
