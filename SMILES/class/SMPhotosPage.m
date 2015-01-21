//
//  SMPhotosPage.m
//  SMILES
//
//  Created by asepmoels on 7/28/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMPhotosPage.h"
#import "iCarousel.h"
#import "EGOImageView.h"
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import "MBProgressHUD.h"
#import "SMMyUserProfile.h"

@interface SMPhotosPage ()<iCarouselDataSource, iCarouselDelegate, UIAlertViewDelegate, ASIHTTPRequestDelegate, MBProgressHUDDelegate, UIActionSheetDelegate>{
    IBOutlet UILabel *name;
    IBOutlet UILabel *photoNum;
    IBOutlet iCarousel *photosView;
    IBOutlet UIButton *submenuButton;
    
    MBProgressHUD *loading;
}


-(IBAction)back:(id)sender;
-(IBAction)showOption:(id)sender;

@end

@implementation SMPhotosPage

@synthesize photoData, username, targetname, displayName;

- (void)dealloc
{
    [username release];
    [targetname release];
    [displayName release];
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [photosView reloadData];
    [self refreshView];
    
    if([self.username isEqualToString:self.targetname]){
        submenuButton.hidden = NO;
    }else{
        submenuButton.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - ACtion
-(void)back:(id)sender{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)refreshView{
    name.text = self.displayName;
    photoNum.text = [NSString stringWithFormat:@"%d / %lu", (int)photosView.currentItemIndex+1, (unsigned long)self.photoData.count];
}

-(void)deletePhoto:(NSInteger)index{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Photo" message:@"Are you sure to delete this photo?" delegate:self cancelButtonTitle:@"No, Don't Delete" otherButtonTitles:@"Yes, Delete It", nil];
    alert.tag = index;
    [alert show];
}

-(void)showOption:(id)sender{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete This Photo" otherButtonTitles:nil];
    [sheet showInView:self.view];
    sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
}

#pragma mark - uiAlertview delegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [alertView release];
    if(buttonIndex == 1){
        NSDictionary *dict = [self.photoData objectAtIndex:alertView.tag];
        
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLPhotoDelete]];
        [request setPostValue:self.username forKey:@"username"];
        [request setPostValue:[dict valueForKey:@"photo_id"] forKey:@"photo_id"];
        request.delegate = self;
        request.tag = alertView.tag;
        [request startAsynchronous];
    }
}

#pragma mark - delegate ASI
-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading hide:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"Failed to contact server" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

-(void)requestStarted:(ASIHTTPRequest *)request{
    if(!loading){
        loading = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loading.delegate = self;
    }
    loading.labelText = @"Deleting photo...";
}

-(void)requestFinished:(ASIHTTPRequest *)request{
    NSDictionary *dict = [[request responseString] JSONValue];
    
    [loading hide:YES];
    if([[dict valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        [self.photoData removeObjectAtIndex:request.tag];
        [photosView reloadData];
        
        SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:self.username];
        [profile load];
        profile.photoCount = self.photoData.count;
        [profile save];
        
        [self refreshView];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:[dict valueForKey:@"MESSAGE"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

#pragma mark - delegate HUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loading release];
    loading = nil;
}

#pragma mark - delegate dan datasource icarousel
-(NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel{
    return self.photoData.count;
}

-(NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel{
    return 0;
}

-(float)carouselItemWidth:(iCarousel *)carousel{
    return 380;
}

-(UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index{
    EGOImageView *view = [[[EGOImageView alloc] initWithFrame:photosView.bounds] autorelease];
    NSString *strURL = [[self.photoData objectAtIndex:index] valueForKey:@"image_url"];
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.clipsToBounds = YES;
    view.imageURL = [NSURL URLWithString:strURL];
    
    return view;
}

-(void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel{
    [self refreshView];
}

#pragma mark - delegate actionsheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [actionSheet release];
    if(buttonIndex == 0){
        [self deletePhoto:photosView.currentItemIndex];
    }
}

@end
