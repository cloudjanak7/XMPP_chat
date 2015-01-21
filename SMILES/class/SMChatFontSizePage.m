//
//  SMChatFontSizePage.m
//  SMILES
//
//  Created by asepmoels on 8/19/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChatFontSizePage.h"
#import "SMMyUserProfile.h"
#import "SMXMPPHandler.h"

@interface SMChatFontSizePage () <UITableViewDataSource, UITableViewDelegate>{
    NSArray *tableData;
    NSInteger currentFontSize;
}

-(IBAction)back:(id)sender;

@end

@implementation SMChatFontSizePage

- (void)dealloc
{
    [tableData release];
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
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    currentFontSize = profile.chatFontSize;
    
    tableData = [[NSArray arrayWithObjects:
                 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:9], @"Extra Small", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:11], @"Small", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:13], @"Medium", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:15], @"Large", nil],
                 [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:17], @"Extra Large", nil], nil] retain];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - delegate dan data source table
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectfontsize"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"selectfontsize"] autorelease];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        UIView *line = [[[UIView alloc] initWithFrame:CGRectMake(0, cell.frame.size.height-1, 320., 1)] autorelease];
        line.backgroundColor = [UIColor grayColor];
        [cell addSubview:line];
    }
    
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *key = [[[dict keyEnumerator] allObjects] lastObject];
    cell.textLabel.text = key;
    NSInteger size = [[dict valueForKey:key] integerValue];
    cell.textLabel.font = [UIFont systemFontOfSize:size];
    
    if(currentFontSize == size)
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *key = [[[dict keyEnumerator] allObjects] lastObject];
    NSInteger size = [[dict valueForKey:key] integerValue];
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    profile.chatFontSize = size;
    [profile save];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
