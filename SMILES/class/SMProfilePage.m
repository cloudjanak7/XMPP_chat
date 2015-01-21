//
//  SMProfilePage.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMProfilePage.h"
#import "XMPPvCardTemp.h"
#import "SMXMPPHandler.h"
#import "SMMyUserProfile.h"
#import "EGOImageView.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"
#import "JSON.h"
#import "SMUpdateProfilePage.h"
#import "EGOCache.h"
#import "SMAppDelegate.h"
#import "IIViewDeckController.h"
#import "SMLeftMenuPage.h"
#import "SMPhotosPage.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "MBProgressHUD.h"

inline static NSString* keyForURL(NSURL* url, NSString* style) {
	if(style) {
		return [NSString stringWithFormat:@"EGOImageLoader-%lu-%lu", (unsigned long)[[url description] hash], (unsigned long)[style hash]];
	} else {
		return [NSString stringWithFormat:@"EGOImageLoader-%lu", (unsigned long)[[url description] hash]];
	}
}

@interface SMProfilePage ()<ASIHTTPRequestDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MBProgressHUDDelegate>{
    IBOutlet EGOImageView *photoProfile;
    IBOutlet UILabel *genderLabel;
    IBOutlet UILabel *photoCountLabel;
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *statusLabel;
    IBOutlet UILabel *displayNameLabel;
    IBOutlet UIActivityIndicatorView *loading;
    IBOutlet UIButton *updateProfileButton;
    IBOutlet UIButton *addPhotoButton;
    
    NSMutableArray *photoDatas;
    MBProgressHUD *loadingView;
    NSOperationQueue *queue;
}

-(IBAction)back:(id)sender;
-(IBAction)updateProfile:(id)sender;
-(IBAction)photos:(id)sender;
-(IBAction)addPhoto:(id)sender;

@end

@implementation SMProfilePage

@synthesize username, myusername;

- (void)dealloc
{
    [photoDatas release];
    [queue release];
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
    queue = [[NSOperationQueue alloc] init];
    [self makeRequest];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self refreshView];
    
    if(![self.myusername isEqualToString:self.username]){
        [[SMMyUserProfile curentProfileForUsername:self.myusername] visit:self.username];
        addPhotoButton.enabled = NO;
        updateProfileButton.enabled = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)back:(id)sender{
    [queue cancelAllOperations];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)makeRequest{
    [loading startAnimating];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLGetProfile]];
    request.delegate = self;
    request.tag = 1;
    [request setPostValue:self.myusername forKey:@"username"];
    [request setPostValue:self.username forKey:@"targetname"];
    [queue addOperation:request];
}

-(void)refreshView{
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:self.username];
    [profile load];
    
    if(profile.avatar.length)
        photoProfile.imageURL = [NSURL URLWithString:profile.avatar];

    if(profile.gender.length > 0)
        genderLabel.text = [[profile.gender capitalizedString] stringByAppendingString:@" |"];
    
    photoCountLabel.text = [NSString stringWithFormat:@"%ld", (long)profile.photoCount];
    usernameLabel.text = [NSString stringWithFormat:@"Username: %@", username];
    
    if(profile.fullname.length)
        displayNameLabel.text = profile.fullname;
    
    if(profile.status.length)
        statusLabel.text = profile.status;
}

-(void)updateProfile:(id)sender{
    SMUpdateProfilePage *update = [[[SMUpdateProfilePage alloc] init] autorelease];
    [self.navigationController pushViewController:update animated:YES];
}

-(void)photos:(id)sender{
    SMPhotosPage *photos = [[[SMPhotosPage alloc] init] autorelease];
    photos.photoData = photoDatas;
    photos.username = self.myusername;
    photos.targetname = self.username;
    photos.displayName = displayNameLabel.text;
    [self.navigationController pushViewController:photos animated:YES];
}

-(void)addPhoto:(id)sender{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", @"Camera", nil];
        sheet.tag = 3;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Image Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Photo Library" otherButtonTitles:@"Saved Photo Album", nil];
        sheet.tag = 2;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }
}

#pragma mark - delegate Actionsheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [actionSheet release];
    if(buttonIndex >= actionSheet.tag)return;
    
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    pickerImage.delegate = self;
    pickerImage.allowsEditing = YES;
    
    if(buttonIndex == 0){
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }else if(buttonIndex == 1){
        pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }else if(buttonIndex == 2){
        pickerImage.sourceType = UIImagePickerControllerSourceTypeCamera;
        pickerImage.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
        
        window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
    }

    [self presentViewController:pickerImage animated:YES completion:nil];
    [pickerImage release];
}

#pragma mark - delegate ImagePicker
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    UIImage *editedImage = [[info valueForKey:@"UIImagePickerControllerEditedImage"] retain];
    //UIImage *originalImage = [[info valueForKey:@"UIImagePickerControllerOriginalImage"] retain];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserUploadPhoto]];
    [request setPostValue:self.username forKey:@"username"];
    NSData *imageData = UIImageJPEGRepresentation(editedImage, 0.7);
    [request setData:imageData withFileName:@"myphoto.jpg" andContentType:@"image/jpeg" forKey:@"image"];
    [request setCompletionBlock:^{
        [loadingView hide:YES];
        [self fetchPhotos];
        
        [[SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user] broadcast:BroadcastTypeAddPhoto];
    }];
    [request setFailedBlock:^{
        [loadingView hide:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed" message:@"upload failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }];
    [queue addOperation:request];
    
    if(!loadingView){
        loadingView = [[MBProgressHUD showHUDAddedTo:self.view animated:YES] retain];
        loadingView.delegate = self;
    }
    loadingView.labelText = @"Uploading Photo...";
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - delegate HUD
-(void)hudWasHidden:(MBProgressHUD *)hud{
    [loadingView release];
    loadingView = nil;
}

#pragma mark - delegate ASIHTPP
-(void)requestFinished:(ASIHTTPRequest *)request{

    [loading stopAnimating];
    
    NSDictionary *response = [[request responseString] JSONValue];
    NSString *state = [response valueForKey:@"STATUS"];
    if([state isEqualToString:@"SUCCESS"]){
        if(request.tag == 1){
            NSDictionary *data = [response valueForKey:@"DATA"];
            
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:self.username];
            profile.admin = [[data valueForKey:@"is_admin"] boolValue];
            profile.userId = [data valueForKey:@"user_id"];
            
            NSString *dob = [data valueForKey:@"dob"];
            if(![dob isEqualToString:@"0000-00-00"]){
                NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
                [format setDateFormat:@"yyyy-MM-dd"];
                profile.birthday = [format dateFromString:dob];
            }
            
            NSString *status = [data valueForKey:@"status"];
            profile.email = [data valueForKey:@"email"];
            profile.fullname = [data valueForKey:@"fullname"];
            profile.gender = [data valueForKey:@"gender"];
            profile.status = status.length>0?status:profile.status;
            profile.username = [data valueForKey:@"username"];
            profile.avatar = [data valueForKey:@"avatar_full"];
            profile.avatarThumb = [data valueForKey:@"avatar"];
            
            [[EGOCache currentCache] removeCacheForKey:keyForURL([NSURL URLWithString:profile.avatarThumb], nil)];
            
            [profile save];
            
            SMAppDelegate *delegate = [UIApplication sharedApplication].delegate;
            SMLeftMenuPage *leftMenu = (SMLeftMenuPage *)delegate.mainViewController.leftController;
            [leftMenu reloadTableView];
            
            [self fetchPhotos];
        }else{
            if(photoDatas){
                [photoDatas release];
                photoDatas = nil;
            }
            
            photoDatas = [response valueForKey:@"DATA"];
            if([photoDatas isKindOfClass:[NSNull class]]){
                photoDatas = nil;
            }else{
                [photoDatas retain];
            }
            
            SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:self.username];
            [profile load];
            profile.photoCount = photoDatas.count;
            [profile save];
        }
    }
    [self refreshView];
}

-(void)fetchPhotos{
    [loading startAnimating];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLUserPhotos]];
    request.delegate = self;
    [request setPostValue:self.myusername forKey:@"username"];
    [request setPostValue:self.username forKey:@"targetname"];
    [queue addOperation:request];
}

-(void)requestFailed:(ASIHTTPRequest *)request{
    [loading stopAnimating];
}

@end
