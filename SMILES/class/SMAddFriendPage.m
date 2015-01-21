//
//  SMAddFriendPage.m
//  SMILES
//
//  Created by asepmoels on 7/23/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMAddFriendPage.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMCreateGroupPage.h"
#import "SMAddFriendByID.h"
#import "ASIFormDataRequest.h"
#import "SMPersistentObject.h"
#import "JSON.h"
#import "SMAppConfig.h"
#import "SMXMPPHandler.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRosterCoreDataStorage.h"
#import "SMProfilePage.h"
#import "SMPopupPage.h"
#import "SMContactSelectPage.h"
#import "SMPersistentObject.h"

@interface SMAddFriendPage () <UITableViewDataSource, UITableViewDelegate, ASIHTTPRequestDelegate, SMXMPPHandlerDelegate, SMPopupPageDelegate>{
    IBOutlet UITableView *thisTableView;
    IBOutlet UITableViewCell *loadingCell;
    
    ASIFormDataRequest *request;
    NSMutableArray *tableData;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMAddFriendPage

- (void)dealloc
{
    [tableData release];
    [request release];
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
    tableData = [[NSMutableArray alloc] init];
    
    NSArray *section0 = [NSArray arrayWithObjects:@"Create a Group", @"Add By ID", @"Invite From Contacts", nil];
    [tableData addObject:section0];
    [tableData addObject:[NSArray array]];
    
    NSArray *contacts = [[SMPersistentObject sharedObject] getRandomContact:50];
    NSMutableArray *tels = [NSMutableArray array];
    NSMutableArray *emails = [NSMutableArray array];
    for(NSDictionary *dict in contacts){
        NSString *email = [dict valueForKey:kTableFieldEmail];
        NSString *tel = [dict valueForKey:kTableFieldPhone];
        
        if(email.length)
            [emails addObject:email];
        if(tel.length)
            [tels addObject:tel];
    }
    NSDictionary *summary = [NSDictionary dictionaryWithObjectsAndKeys:tels, @"t", emails, @"e", nil];
    
    request = [[ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLFriendRecommend]] retain];
    [request setPostValue:[summary JSONRepresentation] forKey:@"list"];
    [request setPostValue:[SMXMPPHandler XMPPHandler].myJID.user forKey:@"username"];
    request.delegate = self;
    [request startAsynchronous];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
    
    if(request.isExecuting)
       [request cancel];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - delegate dan data source tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return tableData.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *isiSection = [tableData objectAtIndex:section];
    return MAX(isiSection.count,1);
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *sectionData = [tableData objectAtIndex:indexPath.section];
    if(sectionData.count < 1)
        return loadingCell;
    
    static NSString *cellIdentifier = @"AddFriendsCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    if(indexPath.section == 0){
        cell.textLabel.text = [sectionData objectAtIndex:indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12.];
        cell.textLabel.textColor = [UIColor darkGrayColor];
        cell.textLabel.highlightedTextColor = [UIColor darkGrayColor];
        cell.textLabel.shadowOffset = CGSizeMake(0, 1);
        cell.textLabel.shadowColor = [UIColor whiteColor];
    }else{
        UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 24)] autorelease];
        [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11.];
        [button setTitle:@"Add" forState:UIControlStateNormal];
        button.tag = indexPath.row;
        [button addTarget:self action:@selector(addUser:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        cell.textLabel.highlightedTextColor = [UIColor darkGrayColor];
        cell.textLabel.shadowOffset = CGSizeMake(0, 1);
        cell.textLabel.shadowColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSArray *array = [tableData objectAtIndex:1];
        NSDictionary *dict = [array objectAtIndex:indexPath.row];
        cell.textLabel.text = [dict valueForKey:@"fullname"];
        cell.imageView.image = [dict valueForKey:@"photo"];
        
        if(!cell.imageView.image)
            cell.imageView.image = [UIImage imageNamed:@"loading.png"];
    }
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    CGRect frame = tableView.bounds;
    frame.size.height = 44.;
    UIView *view = [[[UIView alloc] initWithFrame:frame] autorelease];
    
    if(section == 1){
        frame.origin.x = 14;
        UILabel *lbl = [[[UILabel alloc] initWithFrame:frame] autorelease];
        lbl.text = @"Friend Recommendations";
        lbl.font = [UIFont boldSystemFontOfSize:12.];
        lbl.textColor = [UIColor grayColor];
        lbl.shadowOffset = CGSizeMake(0, 1);
        lbl.shadowColor = [UIColor whiteColor];
        lbl.backgroundColor = [UIColor clearColor];
        [view addSubview:lbl];
    }
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if(section == 1)
        return 44.;
    
    return 12.;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    
    if(indexPath.section == 0){
        if(indexPath.row == 0){
            SMCreateGroupPage *group = [[[SMCreateGroupPage alloc] init] autorelease];
            [delegate.viewController pushViewController:group animated:YES];
        }else if(indexPath.row == 1){
            SMAddFriendByID *friend = [[[SMAddFriendByID alloc] init] autorelease];
            [delegate.viewController pushViewController:friend animated:YES];
        }else if(indexPath.row == 2){
            SMPopupPage *popup = [[SMPopupPage alloc] initWithType:SMPopupTypeInviteFriend];
            popup.delegate = self;
            [popup show];
        }
    }else{
        NSArray *array = [tableData objectAtIndex:1];
        NSDictionary *dict = [array objectAtIndex:indexPath.row];
        NSString *username = [dict valueForKey:@"username"];
        
        SMProfilePage *profile = [[[SMProfilePage alloc] init] autorelease];
        profile.username = [SMXMPPHandler XMPPHandler].myJID.user;
        profile.myusername = username;
        [self.navigationController pushViewController:profile animated:YES];
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

-(void)addUser:(UIButton *)sender{
    NSMutableArray *arr = [tableData objectAtIndex:1];
    NSDictionary *dict = [arr objectAtIndex:sender.tag];
    NSString *username = [dict valueForKey:@"username"];
    NSString *jidUser = nil;
    if([username rangeOfString:@"@"].length < 1){
        jidUser = [username stringByAppendingString:@"@lb1.smilesatme.com"];
    }
    
    [[SMXMPPHandler XMPPHandler] addFriend:jidUser withNickName:username];
    [arr removeObjectAtIndex:sender.tag];
    
    [thisTableView reloadData];
}

#pragma mark - delegate http
-(void)requestFinished:(ASIHTTPRequest *)request2{
    [tableData removeLastObject];
    
    NSDictionary *reply = [[request2 responseString] JSONValue];
    NSArray *data = [reply valueForKey:@"DATA"];
    self.contactData = data;
    
    if([data isKindOfClass:[NSArray class]]){
        if(data.count > 0){
            [tableData addObject:data];
        }
    }else{
        [thisTableView reloadData];
        return;
    }
    /*
    // baris yang ini musti dilewat, cuma buat test saja
    data = [@"[{\"fullname\":\"Awan Naters\", \"username\":\"ujang\"}\
            {\"fullname\":\"Dheinaku\", \"username\":\"dheina\"},\
            {\"fullname\":\"Saha Ieu\", \"username\":\"dheinaku\"}]" JSONValue];
    [tableData addObject:data];
    // hapus sampai sini*/
    
    [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
    for(NSMutableDictionary *dict in data){
        NSString *username = [dict valueForKey:@"username"];
        
        if([username rangeOfString:@"@"].length < 1){
            username = [username stringByAppendingString:@"@lb1.smilesatme.com"];
        }
        
        XMPPUserCoreDataStorageObject *user = [[SMXMPPHandler XMPPHandler] userWithJID:[XMPPJID jidWithString:username]];
        
        if(user.photo){
            [dict setValue:user.photo forKey:@"photo"];
        }else{
            [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:[XMPPJID jidWithString:username]];
        }
    }
    
    [thisTableView reloadData];
}

#pragma mark - delegate SMXMPPHandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeAvatar){
        NSDictionary *dict = [info valueForKey:@"info"];
        NSString *jid = [dict valueForKey:@"jid"];
        UIImage *photo = [dict valueForKey:@"photo"];
        
        NSMutableArray *arr = [tableData objectAtIndex:1];
        for(NSMutableDictionary *dict in arr){
            if([[dict valueForKey:@"username"] isEqualToString:[XMPPJID jidWithString:jid].user]){
                [dict setValue:photo forKey:@"photo"];
                break;
            }
        }
        
        [thisTableView reloadData];
    }
}

#pragma mark - popup delegate
-(void)smpopupView:(SMPopupPage *)viewController didSelectItemAtIndex:(NSInteger)index info:(NSDictionary *)info{
    [viewController release];
    SMContactSelectPage *select = [[SMContactSelectPage alloc] init];
    select.multiselect = YES;
    select.aryRecommend = tableData;
    if(index == 0){
        select.data = [[SMPersistentObject sharedObject] contactArrayWithPhone];
        select.isEmail = NO;
        int contacts = (int)[select.data count];
        if (contacts > 0) {
            for (int index = 0; index < contacts; index++) {
                NSString* phone = [[select.data objectAtIndex:index] objectForKey:@"phone"];
                if ([[phone substringToIndex:1] isEqualToString:@"+"]) {
                    
                }
                else
                    phone = [NSString stringWithFormat:@"+%@", phone];
                
                int recommendations = (int)[self.contactData count];
                for(int indexOfRecommendations = 0; indexOfRecommendations < recommendations; indexOfRecommendations++)
                {
                    if ([phone isEqualToString:[[self.contactData objectAtIndex:indexOfRecommendations] objectForKey:@"msisdn"]]) {
                        [[select.data objectAtIndex:index] setObject:@"1" forKey:@"registered"];
                    }
                }
            }
        }
    }else if(index == 1){
        select.data = [[SMPersistentObject sharedObject] contactArrayWithEmail];
        select.isEmail = YES;
        int contacts = (int)[select.data count];
        if (contacts > 0) {
            for (int index = 0; index < contacts; index++) {
                NSString* email = [[select.data objectAtIndex:index] objectForKey:@"email"];
                int recommendations = (int)[self.contactData count];
                for(int indexOfRecommendations = 0; indexOfRecommendations < recommendations; indexOfRecommendations++)
                {
                    if ([email isEqualToString:[[self.contactData objectAtIndex:indexOfRecommendations] objectForKey:@"email"]]) {
                        [[select.data objectAtIndex:index] setObject:@"1" forKey:@"registered"];
                    }
                }
            }
        }
    }
    [self.navigationController pushViewController:select animated:YES];
    [select release];
}

@end
