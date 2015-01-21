//
//  SMRoomListPage.m
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMRoomListPage.h"
#import "SMChatPage.h"
#import "SMXMPPHandler.h"
#import "SMChatPage.h"
#import "XMPPRoom.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "MBProgressHUD.h"

@interface SMRoomListPage () <SMXMPPHandlerDelegate, MBProgressHUDDelegate>{
    IBOutlet UITableView *table;
    
    MBProgressHUD *loading;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMRoomListPage

@synthesize roomsData;

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
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.roomsData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"blockedtablecell"];
    
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"blockedtablecell"];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;    }
    
    NSDictionary *dict = [self.roomsData objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [dict valueForKey:@"name"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableDictionary *dict = [self.roomsData objectAtIndex:indexPath.row];
    NSString *jidStr = [dict valueForKey:@"jid"];
    //NSString *name = [dict valueForKey:@"name"];
    
    [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
    [[SMXMPPHandler XMPPHandler] createGroup:jidStr];
    
    loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
    loading.delegate = self;
    loading.labelText = @"Joining to Room...";
}

#pragma mark - mbprogress delegate
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
}

#pragma mark - delegate XMPPHandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeGroupReady){
        [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
        
        [loading hide:YES];
        /*
        XMPPRoom *room = [info valueForKey:@"sender"];
        
        SMChatPage *chat = [[SMChatPage alloc] init];
        chat.groupChat = YES;
        chat.myJID = [SMXMPPHandler XMPPHandler].myJID;
        chat.withJID = room.roomJID;
        chat.room = room;
        [self.navigationController pushViewController:chat animated:YES];
        [chat release];*/
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

-(void)reloadView{
    [table reloadData];
}

@end
