//
//  SMBlockedPage.m
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMBlockedPage.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMProfilePage.h"
#import "SMXMPPHandler.h"
#import "SMLeftMenuPage.h"

@interface SMBlockedPage ()<UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableViewCell *blankCell;
    IBOutlet UITableView *table;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMBlockedPage

@synthesize blockedData;

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

-(void)unblock:(UIButton *)sender{
    NSDictionary *dict = [self.blockedData objectAtIndex:sender.tag];
    NSString *username = [dict valueForKey:@"name"];
    if([username rangeOfString:@"@"].length < 1){
        username = [username stringByAppendingString:@"@lb1.smilesatme.com"];
    }
    
    [[SMXMPPHandler XMPPHandler] blockFriend:[XMPPJID jidWithString:username] block:NO];

    [[SMXMPPHandler XMPPHandler] acceptFriend:[XMPPJID jidWithString:username]];
    [self.blockedData removeObjectAtIndex:sender.tag];
    [table reloadData];
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [((SMLeftMenuPage *)delegate.mainViewController.leftController) reloadTableView];
}

#pragma mark - delegate dan data source tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return MAX(self.blockedData.count, 1);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"blockedtablecell"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"blockedtablecell"] autorelease];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        
        UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 24)] autorelease];
        [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11.];
        cell.accessoryView = button;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        
        [button addTarget:self action:@selector(unblock:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Unblock" forState:UIControlStateNormal];
    }
    
    if(self.blockedData.count < 1){
        return blankCell;
    }
    
    NSDictionary *dict = [self.blockedData objectAtIndex:indexPath.row];
    cell.textLabel.text = [[[dict valueForKey:@"name"] componentsSeparatedByString:@"@"] objectAtIndex:0];
    UIImage *photo = [dict valueForKey:@"photo"];
    cell.imageView.image = photo?photo:[UIImage imageNamed:@"loading.png"];
    
    UIButton *btn = (UIButton *)cell.accessoryView;
    btn.tag = indexPath.row;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if(blockedData.count < 1)return;
    
    NSDictionary *dict = [self.blockedData objectAtIndex:indexPath.row];
    
    NSString *user = [[[dict valueForKey:@"name"] componentsSeparatedByString:@"@"] objectAtIndex:0];
    
    SMProfilePage *profile = [[SMProfilePage alloc] init];
    profile.myusername = [SMXMPPHandler XMPPHandler].myJID.user;
    profile.username = user;
    [self.navigationController pushViewController:profile animated:YES];
}

@end
