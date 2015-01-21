//
//  SMAddFriendByID.m
//  SMILES
//
//  Created by asepmoels on 7/23/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "Define.h"

#import "SMAddFriendByID.h"
#import "SMStandardTextField.h"
#import "SMXMPPHandler.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "SMProfilePage.h"


@interface SMAddFriendByID () <ASIHTTPRequestDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, SMXMPPHandlerDelegate>{
    IBOutlet SMStandardTextField *textField;
    IBOutlet UITableView *table;
    IBOutlet UITableViewCell *loadingCell;
    IBOutlet UITableViewCell *notFoundCell;
    UITableViewCell *currentCell;
    
    NSMutableArray *tableData;
    BOOL isLoading;
    ASIFormDataRequest *request;
}

-(IBAction)back:(id)sender;
-(IBAction)addUser:(id)sender;
-(IBAction)search:(id)sender;

@end

@implementation SMAddFriendByID

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
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    tableData = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postFriendRequestByID:) name:ADD_FRIEND_BY_ID object:nil];
}
-(void) postFriendRequestByID:(NSNotification *) not
{
//    NSString * responseString = (NSString *) not.object;
    
    [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"This user isn't available for chatting." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil] show];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
}

#pragma mark - Action
-(void)back:(id)sender{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)search:(id)sender{
    [textField resignFirstResponder];
    if(textField.text.length < 2){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"minimum 2 character length of search user ID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    if(request){
        [request cancel];
        [request release];
        request = nil;
        [self requestFailed:nil];
    }
    
    request = [[ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserSearch]] retain];
    request.delegate = self;
    [request setPostValue:textField.text forKey:@"keyword"];
    [request startAsynchronous];
    
    textField.text = @"";
}

-(void)addUser:(UIButton *)sender{
    
    [table reloadData];
    
    NSDictionary *dict = [tableData objectAtIndex:sender.tag];
    NSString *friendstring = [dict valueForKey:@"username"];
    if([friendstring componentsSeparatedByString:@"@"].count < 2)
        friendstring = [friendstring stringByAppendingString:@"@lb1.smilesatme.com"];
    [[SMXMPPHandler XMPPHandler] addFriend:friendstring withNickName:[[friendstring componentsSeparatedByString:@"@"] objectAtIndex:0]];
    [[SMXMPPHandler XMPPHandler] fetchRoster];
}

#pragma mark - delegate dan datasource tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(isLoading)
        return 1;
    
    return tableData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(isLoading)
        return currentCell;
    
    static NSString *cellIdentifier = @"AddFriendsByIdCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
        
        UIButton *button = [[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 24)] autorelease];
        [button setBackgroundImage:[UIImage imageNamed:@"button-litle.png"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:11.];
        [button setTitle:@"Add" forState:UIControlStateNormal];
        button.tag = indexPath.row;
        [button setTitle:@"Pending" forState:UIControlStateDisabled];
        [button addTarget:self action:@selector(addUser:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = button;
        
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        cell.textLabel.highlightedTextColor = [UIColor darkGrayColor];
        cell.textLabel.shadowOffset = CGSizeMake(0, 1);
        cell.textLabel.shadowColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    UIButton *button = (UIButton *)cell.accessoryView;
    button.tag = indexPath.row;
    
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *user = [dict valueForKey:@"username"];
    
    cell.textLabel.text = user;
    cell.imageView.image = [dict valueForKey:@"photo"];
    
    if(!cell.imageView.image){
        if([[dict valueForKey:@"gender"] isEqualToString:@"pria"])
            cell.imageView.image = [UIImage imageNamed:@"avatar_male.jpg"];
        else
            cell.imageView.image = [UIImage imageNamed:@"avatar_female.jpg"];
    }
    
    if([user rangeOfString:@"@"].length < 1){
        user = [user stringByAppendingString:@"@lb1.smilesatme.com"];
    }
    
    XMPPUserCoreDataStorageObject *userData = [[SMXMPPHandler XMPPHandler] userWithJID:[XMPPJID jidWithString:user]];
    button.enabled = userData?NO:YES;
    button.hidden = [user isEqualToString:[SMXMPPHandler XMPPHandler].myJID.bare];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *user = [dict valueForKey:@"username"];
    
    SMProfilePage *profile = [[SMProfilePage alloc] init];
    profile.myusername = [SMXMPPHandler XMPPHandler].myJID.user;
    profile.username = user;
    [self.navigationController pushViewController:profile animated:YES];
}

#pragma mark - delegate http
-(void)requestFailed:(ASIHTTPRequest *)request{
    isLoading = NO;
    [table reloadData];
}

-(void)requestStarted:(ASIHTTPRequest *)request{
    [tableData removeAllObjects];
    currentCell = loadingCell;
    isLoading = YES;
    [table reloadData];
}

-(void)requestFinished:(ASIHTTPRequest *)_request{
    isLoading = NO;
    NSDictionary *dict = [[_request responseString] JSONValue];
    
    if([[dict valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        NSMutableArray *users = [dict valueForKey:@"USERS"];
        if(users.count > 0){
            if(tableData){
                [tableData release];
            }
            tableData = [users retain];
        }else{
            currentCell = notFoundCell;
            isLoading = YES;
        }
    }else{
        [self requestFailed:_request];
    }
    
    [self fetchPhoto];
}

-(void)fetchPhoto{
    [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
    for(NSMutableDictionary *dict in tableData){
        NSString *username = [dict valueForKey:@"username"];
        
        if([username rangeOfString:@"@"].length < 1){
            username = [username stringByAppendingString:@"@lb1.smilesatme.com"];
        }
        
        XMPPJID *jid = [XMPPJID jidWithString:username];
        XMPPUserCoreDataStorageObject *user = [[SMXMPPHandler XMPPHandler] userWithJID:jid];
        
        if(user.photo){
            [dict setValue:user.photo forKey:@"photo"];
        }else{
            [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:jid];
        }
    }
    
    [table reloadData];
}

#pragma mark - delegate SMXMPPhandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeAvatar){
        NSDictionary *result = [info valueForKey:@"info"];
        NSString *user = [[[result valueForKey:@"jid"] componentsSeparatedByString:@"@"] objectAtIndex:0];
        UIImage *image = [result valueForKey:@"photo"];
        
        for(NSMutableDictionary *dict in tableData){
            NSString *username = [dict valueForKey:@"username"];
            
            if([user isEqualToString:username]){
                [dict setValue:image forKey:@"photo"];
            }
        }
        [table reloadData];
    }else if(type == XMPPHandlerExecuteTypeRoster){
        [table reloadData];
    }
}

#pragma mark - delegate textfield
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self search:nil];
    return NO;
}

@end
