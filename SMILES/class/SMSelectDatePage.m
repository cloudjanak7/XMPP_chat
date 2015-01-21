//
//  SMSelectDatePage.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMSelectDatePage.h"

@interface SMSelectDatePage (){
    IBOutlet UIDatePicker *picker;
}

-(IBAction)back:(id)sender;
-(IBAction)selectDate:(id)sender;

@end

@implementation SMSelectDatePage

@synthesize delegate;

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
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)selectDate:(id)sender{
    if(delegate && [delegate respondsToSelector:@selector(SMSelectDatePage:didSelectDate:)]){
        [delegate SMSelectDatePage:self didSelectDate:picker.date];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)setDate:(NSDate *)date{
    [picker setDate:date];
}

@end
