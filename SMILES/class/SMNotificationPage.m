//
//  SMNotificationPage.m
//  SMILES
//
//  Created by asepmoels on 8/5/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMNotificationPage.h"
#import "SMAppDelegate.h"
#import "SMLeftMenuPage.h"
#import "IIViewDeckController.h"

@interface SMNotificationPage ()<UITableViewDataSource, UITableViewDelegate>{
    IBOutlet UIButton *leftButton;
    IBOutlet UIButton *rightButton;
}

-(IBAction)openLeftMenu:(id)sender;
-(IBAction)openRightMenu:(id)sender;

@end

@implementation SMNotificationPage

@synthesize data, mainScreenMode;

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
    
    if(!self.mainScreenMode){
        rightButton.hidden = YES;
        [leftButton removeTarget:self action:@selector(openLeftMenu:) forControlEvents:UIControlEventTouchUpInside];
        [leftButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)back{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - data source and delegate tableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dict = [self.data objectAtIndex:indexPath.row];
    NSString *text = [dict valueForKey:@"message"];
    
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:13.] constrainedToSize:CGSizeMake(300., 2000.) lineBreakMode:NSLineBreakByWordWrapping];
    
    return fmaxf(50., size.height + 40.);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableviewcellnotifsimple"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"tableviewcellnotifsimple"] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:13.];
        cell.textLabel.numberOfLines = 0;
    }
    
    NSDictionary *dict = [self.data objectAtIndex:indexPath.row];
    cell.textLabel.text = [dict valueForKey:@"message"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"\xF0\x9F\x95\x91 %@", [self getTimeText:[dict valueForKey:@"timestamp"]]];
    [cell.textLabel sizeToFit];
    
    return cell;
}

-(NSString *)getTimeText:(NSDate *)date{
    NSTimeInterval timeGap = [[NSDate date] timeIntervalSinceDate:date];
    
    if(timeGap < 60)
        return @"about 1 minute ago";
    else if(timeGap <= 60*60)
        return @"about 1 hour ago";
    else if(timeGap < 24*60*60){
        int jml =  (int)timeGap/3600;
        return [NSString stringWithFormat:@"about %d hour%@ ago", jml, jml>1?@"s":@""];
    }
    else if(timeGap < 7*24*60*60){
        int jml =  (int)timeGap/(24*3600);
        return [NSString stringWithFormat:@"about %d day%@ ago", jml, jml>1?@"s":@""];
    }
    
    return @"more than 1 week ago";
}

@end
