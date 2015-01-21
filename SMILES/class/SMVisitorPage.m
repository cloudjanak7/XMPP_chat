//
//  SMVisitorPage.m
//  SMILES
//
//  Created by asepmoels on 8/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMVisitorPage.h"
#import "SMVisitorCell.h"
#import "SMPersistentObject.h"
#import "SMXMPPHandler.h"
#import "XMPPvCardTemp.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRosterCoreDataStorage.h"
#import "SMProfilePage.h"
#import "SMAppDelegate.h"
#import "SMLeftMenuPage.h"
#import "IIViewDeckController.h"

@interface SMVisitorPage ()<SMXMPPHandlerDelegate, UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UITableView *table;
    
    NSMutableArray *tableData;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMVisitorPage

- (void)dealloc
{
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
    tableData = [[[SMPersistentObject sharedObject] getVisitors:20] retain];
    
    for(NSDictionary *dict in tableData){
        NSString *user = [dict valueForKey:kTableFieldName];
        
        if([user rangeOfString:@"@"].length < 1){
            user = [user stringByAppendingString:@"@lb1.smilesatme.com"];
        }
        
        XMPPJID *jid = [XMPPJID jidWithString:user];

        XMPPUserCoreDataStorageObject *obj = [[SMXMPPHandler XMPPHandler] userWithJID:jid];
        if(!obj.photo){
            [[SMXMPPHandler XMPPHandler] fetchvCardTemoForJID:jid];
            [[SMXMPPHandler XMPPHandler] addXMPPHandlerDelegate:self];
        }
    }
    
    [table reloadData];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[SMXMPPHandler XMPPHandler] removeXMPPHandlerDelegate:self];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    [[SMPersistentObject sharedObject] clearUnviewedVisitor];
    SMAppDelegate *del = [UIApplication sharedApplication].delegate;
    SMLeftMenuPage *left = (SMLeftMenuPage *)del.mainViewController.leftController;
    [left reloadTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - delegate dan data source tableview
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 47.;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return tableData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    SMVisitorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SMVisitorCell"];
    
    if(!cell){
        NSArray *arr = [[NSBundle mainBundle] loadNibNamed:@"SMVisitorCell" owner:self options:nil];
        
        for(SMVisitorCell *one in arr){
            if([one isKindOfClass:[SMVisitorCell class]]){
                cell = one;
            }
        }
    }
    
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *user = [dict valueForKey:kTableFieldName];
    
    if([user rangeOfString:@"@"].length < 1){
        user = [user stringByAppendingString:@"@lb1.smilesatme.com"];
    }
    
    XMPPJID *jid = [XMPPJID jidWithString:user];
    XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:jid];
    XMPPUserCoreDataStorageObject *obj = [[SMXMPPHandler XMPPHandler] userWithJID:jid];
    
    if(temp.givenName.length){
        if(temp.middleName.length){
            cell.name.text = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
        }else{
            cell.name.text = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
        }
    }else if(obj.nickname.length)
        cell.name.text = [NSString stringWithFormat:@"%@", obj.nickname];
    else
        cell.name.text = obj.jid.user;
    
    if(cell.name.text.length < 1)
        cell.name.text = jid.user;
    
    cell.foto.image = obj.photo?obj.photo:[UIImage imageNamed:@"avatar_male.jpg"];
    cell.time.text = [self getTimeText:[dict valueForKey:kTableFieldDate]];
    cell.bg.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.];
    
    BOOL viewed = [[dict valueForKey:kTableFieldViewed] boolValue];
    if(!viewed){
        cell.bg.backgroundColor = [UIColor colorWithRed:0.8 green:0.6 blue:0.6 alpha:1.];
        [UIView beginAnimations:@"" context:nil];
        [UIView setAnimationDuration:3.];
        cell.bg.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.];
        [UIView commitAnimations];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *user = [dict valueForKey:kTableFieldName];
    SMProfilePage *newPage = [[SMProfilePage alloc] init];
    newPage.username = user;
    newPage.myusername = [SMXMPPHandler XMPPHandler].myJID.user;
    
    SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    [delegate.viewController pushViewController:newPage animated:YES];
    
    [newPage release];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(NSString *)getTimeText:(NSDate *)date{
    NSTimeInterval timeGap = [[NSDate date] timeIntervalSinceDate:date];
    
    if(timeGap < 60)
        return @"1 minute ago";
    else if(timeGap <= 60*60)
        return @"1 hour ago";
    else if(timeGap < 24*60*60){
        int jml =  (int)timeGap/3600;
        return [NSString stringWithFormat:@"%d hour%@ ago", jml, jml>1?@"s":@""];
    }
    else if(timeGap < 7*24*60*60){
        int jml =  (int)timeGap/(24*3600);
        return [NSString stringWithFormat:@"%d day%@ ago", jml, jml>1?@"s":@""];
    }
    
    return @"more than 1 week ago";
}

#pragma mark - delegate xmpphandler
-(void)SMXMPPHandler:(SMXMPPHandler *)handler didFinishExecute:(XMPPHandlerExecuteType)type withInfo:(NSDictionary *)info{
    if(type == XMPPHandlerExecuteTypeAvatar)
        [table reloadData];
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

@end
