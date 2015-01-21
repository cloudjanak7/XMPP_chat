//
//  SMReportPage.m
//  SMILES
//
//  Created by Jie Meng on 1/25/14.
//  Copyright (c) 2014 asepmoels. All rights reserved.
//

#import "SMReportPage.h"
#import "SMAppConfig.h"
#import <QuartzCore/QuartzCore.h>
#import "ASIFormDataRequest.h"
#import "MBProgressHUD.h"
#import "JSON.h"

@interface SMReportPage () <ASIHTTPRequestDelegate, MBProgressHUDDelegate> {
    NSOperationQueue *queue;
}

@property (nonatomic, retain) MBProgressHUD *reporting;
@property (weak, nonatomic) IBOutlet UILabel *lbSender;
@property (weak, nonatomic) IBOutlet UILabel *lbSuspect;
@property (weak, nonatomic) IBOutlet UIImageView *ivPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnAttach;

@end

@implementation SMReportPage

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
    // Do any additional setup after loading the view from its nib.
    
    self.lbSender.layer.borderColor = [UIColor blackColor].CGColor;
    self.lbSender.layer.borderWidth = 1.0f;
    self.lbSuspect.layer.borderColor = [UIColor blackColor].CGColor;
    self.lbSuspect.layer.borderWidth = 1.0f;
    
    [self.lbSender setText:[NSString stringWithFormat:@"  %@", self.sSender]];
    [self.lbSuspect setText:[NSString stringWithFormat:@"  %@", self.sSuspect]];
    
    queue = [[NSOperationQueue alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Events

- (IBAction)onBackBtnPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onAttachBtnPressed:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Photo Library", @"Saved Photo Album", @"Camera", nil];
    [sheet showInView:self.view];
    sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
}

- (IBAction)onReportBtnPressed:(id)sender
{
    if(queue.operationCount > 0){
        return;
    }
    
    UIImage *image = self.ivPhoto.image;
    if (image == NULL) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Please attach image." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return;
    }
    
    self.reporting = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.reporting.mode = MBProgressHUDModeIndeterminate;
    self.reporting.delegate = self;
    self.reporting.labelText = @"Reporting..";
    
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    NSString *mime = @"image/jpeg";
    NSString *fileName = @"image.jpg";
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLReportUser]];
    [request setPostValue:self.sSender forKey:@"sender_username"];
    [request setPostValue:self.sSuspect forKey:@"suspect_username"];
    [request setData:data withFileName:fileName andContentType:mime forKey:@"image"];
    [request setTimeOutSeconds:5000];
    request.delegate = self;
    [queue addOperation:request];
}

-(UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - UIActionSheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    @try {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        
        switch (buttonIndex) {
            case 0:
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            case 1:
                picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
                break;
            case 2:
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                break;
            case 3:
                return;
            default:
                break;
        }
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        {
            UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
            window.clipsToBounds = YES;
            if (buttonIndex == 2) {
                [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
            } else
                [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
            window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
            window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        }

        [self presentViewController:picker animated:YES completion:^{
            
        }];
    }
    @catch (NSException *exception) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"No Camera" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
    @finally {
        
    }
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *img = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    CGSize szScaled = CGSizeMake(self.ivPhoto.frame.size.width, img.size.height * self.ivPhoto.frame.size.width / img.size.width);
    self.ivPhoto.image = [self scaleImage:img toSize:szScaled];
    [self.btnAttach setTitle:@"" forState:UIControlStateNormal];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
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

#pragma mark - ASIHTTPRequest Delegate

-(void)requestFailed:(ASIHTTPRequest *)request
{
    [[[UIAlertView alloc] initWithTitle:@"Check Your Internet Connection." message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    
    [self.reporting hide:YES];
}

-(void)requestFinished:(ASIHTTPRequest *)request
{
    [self.reporting hide:YES];
    
    NSDictionary *reply = [[request responseString] JSONValue];
    NSString *message = [reply valueForKey:@"MESSAGE"];
    [[[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    [self.navigationController popViewControllerAnimated:YES];
    
    if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
        
    }else{
        
    }
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [hud removeFromSuperview];
    self.reporting = nil;
}

@end
