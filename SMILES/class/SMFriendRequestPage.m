//
//  SMFriendRequestPage.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMFriendRequestPage.h"
#import "IIViewDeckController.h"
#import "SMAppDelegate.h"
#import "SMXMPPHandler.h"
#import "XMPPJID.h"
#import "SMLeftMenuPage.h"
#import "SMProfilePage.h"

@interface SMFriendRequestPage () <UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *table;
    IBOutlet UITableViewCell *emptycell;
    IBOutlet UITableViewCell *emptycell2;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMFriendRequestPage

@synthesize requestData, myRequestData;

- (void)dealloc
{
    [super dealloc];
}

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

#pragma mark - delegate dan data source tableview
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(section == 0)
        return MAX(self.requestData.count, 1);
    
    return MAX(self.myRequestData.count, 1);
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 42;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320., 42)] autorelease];
    view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.];
    
    UILabel *label = [[[UILabel alloc] initWithFrame:view.frame] autorelease];
    label.font = [UIFont systemFontOfSize:13.];
    label.textColor = [UIColor grayColor];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0, 1);
    label.backgroundColor = [UIColor clearColor];
    CGRect buttonFrame = CGRectMake((view.frame.size.width - 10 - 74.), (view.frame.size.height-30)*0.5, 74, 30);
    UIButton *button = [[[UIButton alloc] initWithFrame:buttonFrame] autorelease];
    [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:12.];
    
    if(section == 0){
        label.text = @" People who add you as a Friend";
        [button setTitle:@"Accept All" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(acceptAllRequest) forControlEvents:UIControlEventTouchUpInside];
    }else{
        label.text = @" Your Pending Request";
        [button setTitle:@"Cancel All" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelAllMyRequest) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [view addSubview:label];
    [view addSubview:button];
    
    return view;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == 0){
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"requesttablecell"];
        
        if(!cell){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"requesttablecell"] autorelease];
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
            
            UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 24)] autorelease];
            [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:11.];
            
            UIButton *button2 = [[[UIButton alloc] initWithFrame:CGRectMake(55, 0, 50, 24)] autorelease];
            [button2 setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
            [button2 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button2.titleLabel.font = [UIFont systemFontOfSize:11.];
            
            UIView *container = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 105, 24)] autorelease];
            [container addSubview:button];
            [container addSubview:button2];
            
            cell.accessoryView = container;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        if(self.requestData.count < 1){
            return emptycell;
        }
        
        NSDictionary *dict = [self.requestData objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict valueForKey:@"name"];
        UIImage *photo = [dict valueForKey:@"photo"];
        cell.imageView.image = photo?photo:[UIImage imageNamed:@"loading.png"];
        
        NSArray *btns = (NSArray *)cell.accessoryView.subviews;
        
        UIButton *btn = [btns objectAtIndex:0];
        [btn setTitle:@"Accept" forState:UIControlStateNormal];
        btn.tag = indexPath.row;
        [btn removeTarget:self action:@selector(acceptFriend:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(acceptFriend:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *btn2 = [btns objectAtIndex:1];
        [btn2 setTitle:@"Decline" forState:UIControlStateNormal];
        btn2.tag = indexPath.row;
        [btn2 removeTarget:self action:@selector(declineFriend:) forControlEvents:UIControlEventTouchUpInside];
        [btn2 addTarget:self action:@selector(declineFriend:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }else{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"requesttablecell2"];
        
        if(!cell){
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"requesttablecell2"] autorelease];
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
            
            UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 24)] autorelease];
            [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:11.];
            cell.accessoryView = button;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }
        
        if(self.myRequestData.count < 1){
            return emptycell2;
        }
        
        NSDictionary *dict = [self.myRequestData objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict valueForKey:@"name"];
        UIImage *photo = [dict valueForKey:@"photo"];
        cell.imageView.image = photo?photo:[UIImage imageNamed:@"loading.png"];
        
        UIButton *btn = (UIButton *)cell.accessoryView;
        [btn setTitle:@"Cancel" forState:UIControlStateNormal];
        btn.tag = indexPath.row;
        [btn removeTarget:self action:@selector(cancelFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(cancelFriendRequest:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = nil;
    
    if(indexPath.section == 0){
        if(requestData.count < 1)return;
        
        dict = [requestData objectAtIndex:indexPath.row];
    }else{
        if(myRequestData.count < 1)return;
        
        dict = [myRequestData objectAtIndex:indexPath.row];
    }
    
    NSString *user = [[[dict valueForKey:@"name"] componentsSeparatedByString:@"@"] objectAtIndex:0];
    
    SMProfilePage *profile = [[SMProfilePage alloc] init];
    profile.myusername = [SMXMPPHandler XMPPHandler].myJID.user;
    profile.username = user;
    [self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - Action
-(void)acceptAllRequest{
    for(NSDictionary *dict in self.requestData){
        NSString *friendstring = [dict valueForKey:@"name"];
        if([friendstring componentsSeparatedByString:@"@"].count < 2)
            friendstring = [friendstring stringByAppendingString:@"@lb1.smilesatme.com"];
        
        XMPPJID *jid = [XMPPJID jidWithString:friendstring];
        [[SMXMPPHandler XMPPHandler] acceptFriend:jid];
    }
    [self.requestData removeAllObjects];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
    [leftMenu reloadTableView];
    [table reloadData];
}

-(void)cancelAllMyRequest{
    for(NSDictionary *dict in self.myRequestData){
        [[SMXMPPHandler XMPPHandler] removeFriend:[dict valueForKey:@"name"]];
    }
    [self.myRequestData removeAllObjects];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
    [table reloadData];
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
    [leftMenu reloadTableView];
    [table reloadData];
}

-(void)acceptFriend:(UIButton *)sender{
    NSDictionary *dict = [self.requestData objectAtIndex:sender.tag];
    NSString *friendstring = [dict valueForKey:@"name"];
    if([friendstring componentsSeparatedByString:@"@"].count < 2)
        friendstring = [friendstring stringByAppendingString:@"@lb1.smilesatme.com"];
    
    XMPPJID *jid = [XMPPJID jidWithString:friendstring];
    [[SMXMPPHandler XMPPHandler] acceptFriend:jid];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
    
    [self.requestData removeObjectAtIndex:sender.tag];
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
    [leftMenu reloadTableView];
    [table reloadData];
}

-(void)declineFriend:(UIButton *)sender{
    NSDictionary *dict = [self.requestData objectAtIndex:sender.tag];
    NSString *friendstring = [dict valueForKey:@"name"];
    if([friendstring componentsSeparatedByString:@"@"].count < 2)
        friendstring = [friendstring stringByAppendingString:@"@lb1.smilesatme.com"];
    
    XMPPJID *jid = [XMPPJID jidWithString:friendstring];
    [[SMXMPPHandler XMPPHandler] declineFriend:jid];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
    
    [self.requestData removeObjectAtIndex:sender.tag];
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
    [leftMenu reloadTableView];
    [table reloadData];
}

-(void)cancelFriendRequest:(UIButton *)sender{
    NSDictionary *dict = [self.myRequestData objectAtIndex:sender.tag];
    [[SMXMPPHandler XMPPHandler] removeFriend:[dict valueForKey:@"name"]];
    [self.myRequestData removeObjectAtIndex:sender.tag];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
    [leftMenu reloadTableView];
    [table reloadData];
}

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

@end
