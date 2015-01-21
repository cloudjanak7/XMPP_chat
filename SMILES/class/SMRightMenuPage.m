//
//  SMRightMenuPage.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMRightMenuPage.h"
#import "SMAppConfig.h"
#import "ASIHTTPRequest.h"
#import "MBProgressHUD.h"
#import "JSON.h"
#import "EGOImageView.h"

@interface SMRightMenuPage () <ASIHTTPRequestDelegate>{
    MBProgressHUD *loading;
}

@end

@implementation SMRightMenuPage

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
    
    for(UIView *v in self.view.subviews){
        UIButton *button = [[UIButton alloc] initWithFrame:v.frame];
        button.tag = v.tag;
        [self.view insertSubview:button aboveSubview:v];
        [button addTarget:self action:@selector(itemTouchedDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(itemTouchedUp:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(itemTouchedCancel:) forControlEvents:UIControlEventTouchDragExit];
        [button release];
    }
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:kURLRightMenu]];
    request.delegate = self;
    [request startAsynchronous];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - delegate asi
-(void)requestStarted:(ASIHTTPRequest *)request{
    loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
    loading.labelText = @"Loading..";
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to contact server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    [loading hide:YES];
    NSDictionary *root = [[request responseString] JSONValue];
    NSArray *streamings = [root valueForKey:@"streaming"];
    
    for(int i=0; i<4; i++){
        NSDictionary *streaming = [streamings objectAtIndex:i];
        NSString *icon = [streaming valueForKey:@"icon"];
        EGOImageView *imageView = [self itemWithTag:i];
        imageView.imageURL = [NSURL URLWithString:icon];
    }
}

-(EGOImageView *)itemWithTag:(NSInteger)tag{
    for(EGOImageView *one in self.view.subviews){
        if(one.tag == tag){
            return one;
        }
    }
    
    return nil;
}

#pragma mark - delegate ProgressHUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [hud removeFromSuperview];
    [loading release];
    loading = nil;
}

#pragma mark - Action
-(void)itemTouchedUp:(UIButton *)btn{
    EGOImageView *view = [self itemWithTag:btn.tag];
    view.alpha = 1.;
    view.transform = CGAffineTransformMakeScale(1., 1.);
}

-(void)itemTouchedCancel:(UIButton *)btn{
    EGOImageView *view = [self itemWithTag:btn.tag];
    view.alpha = 1;
    view.transform = CGAffineTransformMakeScale(1., 1.);
}

-(void)itemTouchedDown:(UIButton *)btn{
    EGOImageView *view = [self itemWithTag:btn.tag];
    view.alpha = 0.7;
    view.transform = CGAffineTransformMakeScale(0.98, 0.98);
}

@end
