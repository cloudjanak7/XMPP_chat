//
//  SMSettingPage.m
//  SMILES
//
//  Created by asepmoels on 7/22/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMSettingPage.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMXMPPHandler.h"
#import "SMProfilePage.h"
#import "SMAboutPage.h"
#import "SMDeleteAccountPage.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "MBProgressHUD.h"
#import "JSON.h"
#import "SMLandingPage.h"

@interface SMSettingPage () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>{
    NSArray *tableData;
    MBProgressHUD *loading;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMSettingPage

- (void)dealloc
{
    if (loading) {
        [loading release];
        loading = NULL;
    }
    
    [tableData release];
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
    tableData = [[NSArray arrayWithObjects:@"My Profile", @"About", @"Term of Service", @"Privacy Policy", @"Delete My Account", @"Logout", nil] retain];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - data source dan delegate tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return tableData.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 48.+12.;
}

-(UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"settingcell";
    
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        
        UIView *bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 42.)];
        bg.backgroundColor = [UIColor clearColor];
        cell.backgroundView = bg;
        [bg release];
        
        UIView *bgFocus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 42.)];
        bgFocus.backgroundColor = [UIColor clearColor];
        cell.selectedBackgroundView = bgFocus;
        
        UIImageView *bgg = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 12, 320, 48)] autorelease];
        bgg.image = [UIImage imageNamed:@"lightlightgray.png"];
        [bgFocus addSubview:bgg];
        
        UIImage *box = [UIImage imageNamed:@"leftcell-box-focus.png"];
        UIImageView *boxView = [[UIImageView alloc] initWithImage:box];
        boxView.frame = CGRectMake(0, 12, 4, 48);
        [bgFocus addSubview:boxView];
        [boxView release];
        [bgFocus release];
        
        UILabel *lbl = [[[UILabel alloc] initWithFrame:CGRectMake(0, 12, 320, 48)] autorelease];
        lbl.font = [UIFont systemFontOfSize:14.];
        lbl.textColor = [UIColor darkGrayColor];
        lbl.shadowColor = [UIColor whiteColor];
        lbl.shadowOffset = CGSizeMake(0, 1);
        lbl.highlightedTextColor = [UIColor colorWithRed:20./255 green:201./255 blue:217./255 alpha:1.];
        lbl.tag = 1;
        lbl.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.];
        [cell addSubview:lbl];
    }
    
    UILabel *lbl = nil;
//    for(UIView *v in cell.subviews){
//        if(v.tag == 1){
//            lbl = (UILabel *)v;
//        }
//    }

    lbl = (UILabel*)[cell viewWithTag:1];
    
    lbl.text = [@"    " stringByAppendingString:[tableData objectAtIndex:indexPath.row]];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.row == 0){
        SMProfilePage *profile = [[[SMProfilePage alloc] init] autorelease];
        profile.username = [SMXMPPHandler XMPPHandler].myJID.user;
        profile.myusername = profile.username;
        SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
        [delegate.viewController pushViewController:profile animated:YES];
    }else if(indexPath.row >= 1 && indexPath.row <= 3){//about, terms, privacy
        SMAboutPage *page = [[[SMAboutPage alloc] init] autorelease];
        page.pageType = (int)indexPath.row;
        [self.navigationController pushViewController:page animated:YES];
    }else if(indexPath.row == 4){
        SMDeleteAccountPage *delete = [[SMDeleteAccountPage alloc] init];
        [self.navigationController pushViewController:delete animated:YES];
        [delete release];
    }else if(indexPath.row == 5){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm" message:@"Are you sure to logout?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

#pragma mark - Action
-(void)openLeftMenu:(id)sender{
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.mainViewController toggleLeftViewAnimated:YES completion:^(IIViewDeckController *controller) {
        
    }];
}

-(void)openRightMenu:(id)sender{
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.mainViewController toggleRightViewAnimated:YES completion:^(IIViewDeckController *controller) {
        
    }];
}

#pragma mark - UI alert view
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [alertView release];
    
    if(buttonIndex == 1){
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserLogout]];
        [request setPostValue:[SMXMPPHandler XMPPHandler].myJID.user forKey:@"username"];
        request.tag = 2;
        request.delegate = self;
        [request startAsynchronous];

        if (!loading) {
            loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
            loading.mode = MBProgressHUDModeIndeterminate;
        }
        loading.labelText = @"Loging out..";
    }
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
        if(request.tag == 2){
            [loading hide:YES];

            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"autosignin"];
            [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"password"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [[SMXMPPHandler XMPPHandler] forceLogout];
            [[SMXMPPHandler XMPPHandler] removeAllXMPPHandlerDelegates];

            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            id target_controller = NULL;
            
            for (UIViewController *target in [delegate.viewController viewControllers]) {
                if ([target isKindOfClass:[SMLandingPage class]]) {
                    target_controller = target;
                    break;
                }
            }
            
            if (target_controller == NULL) {
                [delegate.viewController popToRootViewControllerAnimated:NO];
                SMLandingPage *landingPage = [[SMLandingPage alloc] init];
                [delegate.viewController pushViewController:landingPage animated:YES];
                [landingPage release];
            } else {
                [delegate.viewController popToViewController:target_controller animated:YES];
            }
            delegate.mainViewController.centerController = (UIViewController *)delegate.contactListPage;
        }
    }else{
        [loading hide:YES];
        NSString *message = [reply valueForKey:@"MESSAGE"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed Logout" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

@end
