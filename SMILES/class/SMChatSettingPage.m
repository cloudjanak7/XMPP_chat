//
//  SMChatSettingPage.m
//  SMILES
//
//  Created by asepmoels on 8/16/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChatSettingPage.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "SMMyUserProfile.h"
#import "SMXMPPHandler.h"
#import "NSData+Base64.h"
#import "XMPPMessageArchivingCoreDataStorage.h"
#import <MessageUI/MessageUI.h>
#import "XMPPvCardTemp.h"
#import "XMPPMessage+MyCustom.h"
#import "SMChatFontSizePage.h"
#import "SMMyUserProfile.h"
#import "SMPersistentObject.h"
#import "XMPPMessage+XEP_0224.h"

@interface SMChatSettingPage () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>{
    IBOutlet UILabel *fontSample;
    NSArray *emoticonsData;
}

-(IBAction)back:(id)sender;
-(IBAction)changeWallpaper:(id)sender;
-(IBAction)deleteChatRecord:(id)sender;
-(IBAction)exportHistory:(id)sender;
-(IBAction)fontSizeSetting:(id)sender;

@end

@implementation SMChatSettingPage

@synthesize friendBare, backgroundToChange, chatDataToChange, tableToRefresh;

- (void)dealloc
{
    [friendBare release];
    [emoticonsData release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        emoticonsData = [[[SMPersistentObject sharedObject] emoticonsGrouped:NO] retain];
    }
    return self;
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
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    fontSample.font = [[UIFont systemFontOfSize:profile.chatFontSize] retain];
    
    switch (profile.chatFontSize) {
        case 9:
            fontSample.text = @"Extra Small";
            break;
        case 11:
            fontSample.text = @"Small";
            break;
        case 13:
            fontSample.text = @"Medium";
            break;
        case 15:
            fontSample.text = @"Large";
            break;
        case 17:
            fontSample.text = @"Extra Large";
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)back:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)changeWallpaper:(id)sender{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Default" otherButtonTitles:@"Photo Library", @"Saved Photo Album", @"Camera", nil];
        sheet.tag = 3;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }else{
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Default" otherButtonTitles:@"Photo Library", @"Saved Photo Album", nil];
        sheet.tag = 2;
        [sheet showInView:self.view];
        sheet.bounds = CGRectOffset(sheet.bounds, 0, 20);
    }
}

-(void)deleteChatRecord:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Once you clear your chat history you won't be able to get it back.\nDelete?" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
    [alert show];
}

-(void)exportHistory:(id)sender{
    NSString *message = @"<table border=\"0\">";
    
    XMPPJID *friendJID = [XMPPJID jidWithString:self.friendBare];
    NSArray *messages = [[XMPPMessageArchivingCoreDataStorage sharedInstance] getMessageWithJid:friendJID streamJid:[SMXMPPHandler XMPPHandler].myJID];
    
    XMPPvCardTemp *temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:friendJID];
    NSString *frienName = friendJID.user;
    if(temp.givenName.length){
        if(temp.middleName.length){
            frienName = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
        }else{
            frienName = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
        }
    }
    
    temp = [[SMXMPPHandler XMPPHandler] vCardTemoForJID:[SMXMPPHandler XMPPHandler].myJID];
    NSString *myName = [SMXMPPHandler XMPPHandler].myJID.user;
    if(temp.givenName.length){
        if(temp.middleName.length){
            myName = [NSString stringWithFormat:@"%@ %@ %@", temp.givenName, temp.middleName, (temp.familyName)?temp.familyName:@""];
        }else{
            myName = [NSString stringWithFormat:@"%@ %@", temp.givenName, (temp.familyName)?temp.familyName:@""];
        }
    }
    
    for(XMPPMessageArchiving_Message_CoreDataObject *obj in messages){
        NSString *from = obj.message.from.bare;
        
        if(![from isEqualToString:friendBare]){
            from = myName;
        }else{
            from = frienName;
        }
        
        NSString *body = @"";
        
        if(obj.message.isBroadcastMessage){
            NSDictionary *dict = obj.message.parsedMessage;
            body = [dict valueForKey:@"message"];
            body = [self parseEmoticons:body];
        }else if(obj.message.isContactMessage){
            NSDictionary *dict = obj.message.parsedMessage;
            body = [NSString stringWithFormat:@"\xE2\x98\x8E %@'s Contact", [dict valueForKey:@"name"]];
        }else if(obj.message.isImageMessage){
            if(obj.message.isFileMessage){
                body = @":: file ::";
            }else{
                body = [NSString stringWithFormat:@"<img src=\"%@\" width=\"80px\" />", obj.message.imageURL.absoluteString];
            }
        }else if(obj.message.isAttentionMessage || obj.message.isAttentionMessage2){
            body = @":: POW ::";
        }else if(obj.message.isLocationMessage){
            if([obj.message.to isEqualToJID:[SMXMPPHandler XMPPHandler].myJID options:XMPPJIDCompareBare]){
                NSString *user = obj.message.from.user;
                
                if(obj.message.isGroupMessage){
                    user = obj.message.from.resource;
                }
                
                body = [NSString stringWithFormat:@"\xF0\x9F\x93\x8D %@'s Location", user];
            }else{
                body = @"\xF0\x9F\x93\x8D My Location";
            }
        }else{
            body = [self parseEmoticons:obj.message.body];
            body = [self parseEmoticons:body];
        }
        
        message = [message stringByAppendingFormat:@"<tr valign=\"top\"><td style=\"color:#000055\">%@</td><td>:</td><td><i>%@</i></td></tr>", [[from stringByReplacingOccurrencesOfString:@" " withString:@"_"] uppercaseString], body];
    }
    
    message = [message stringByAppendingString:@"</table>"];
    
    MFMailComposeViewController *emailComposer = [[MFMailComposeViewController alloc] init];
    emailComposer.mailComposeDelegate = self;
    [emailComposer setSubject:@"SMILES (Chat Archive)"];
    [emailComposer setTitle:@"SMILES (Chat Archive)"];
    [emailComposer setMailComposeDelegate:self];
    [emailComposer setMessageBody:message isHTML:YES];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault];
        
        window.bounds = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
    }

    [self presentViewController:emailComposer animated:YES completion:nil];
}

-(void)fontSizeSetting:(id)sender{
    SMChatFontSizePage *fontSize = [[SMChatFontSizePage alloc] init];
    [self.navigationController pushViewController:fontSize animated:YES];
    [fontSize release];
}

-(NSString *)parseEmoticons:(NSString *)str{
    for(NSDictionary *dict in emoticonsData){
        NSString *plain = [dict valueForKey:kTableFieldPlain];
        NSString *replace = [dict valueForKey:kTableFieldUnicode];
        
        str = [str stringByReplacingOccurrencesOfString:plain withString:replace];
    }
    
    return str;
}

#pragma mark - delegate Actionsheet
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [actionSheet release];
    if(buttonIndex > actionSheet.tag)return;
    
    UIImagePickerController *pickerImage = [[UIImagePickerController alloc] init];
    pickerImage.delegate = self;
    pickerImage.allowsEditing = NO;
    
    if(buttonIndex == 0){
        [pickerImage release];
        
        SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
        [profile load];
        if(profile.chatBackgrounds == nil){
            profile.chatBackgrounds = [NSMutableDictionary dictionary];
        }
        UIImage *originalImage = [UIImage imageNamed:@"bgchat.jpg"];
        self.backgroundToChange.image = originalImage;
        [profile.chatBackgrounds removeObjectForKey:self.friendBare];
        [profile save];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }else if(buttonIndex == 1){
        pickerImage.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }else if(buttonIndex == 2){
        pickerImage.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }else if(buttonIndex == 3){
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
    
    UIImage *originalImage = [info valueForKey:@"UIImagePickerControllerOriginalImage"];
    
    SMMyUserProfile *profile = [SMMyUserProfile curentProfileForUsername:[SMXMPPHandler XMPPHandler].myJID.user];
    [profile load];
    if(profile.chatBackgrounds == nil){
        profile.chatBackgrounds = [NSMutableDictionary dictionary];
    }
    self.backgroundToChange.image = originalImage;
    NSData *imageData = UIImageJPEGRepresentation(originalImage, 0.7);
    
    NSArray *arr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filename = [NSString stringWithFormat:@"imgbg%lf", [NSDate timeIntervalSinceReferenceDate]];
    NSString *path = [[arr lastObject] stringByAppendingPathComponent:filename];
    NSError *error;
    [[imageData base64EncodedString] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    [profile.chatBackgrounds setValue:path forKey:self.friendBare];
    [profile save];
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - delegate Alert
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [alertView release];
    if(buttonIndex == 0){
        [[XMPPMessageArchivingCoreDataStorage sharedInstance] deleteMessageForJID:[XMPPJID jidWithString:self.friendBare] streamJid:[SMXMPPHandler XMPPHandler].myJID];
        [self.chatDataToChange removeAllObjects];
        [self.tableToRefresh reloadData];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - delegate email
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
    {
        UIWindow *window = [[UIApplication sharedApplication].windows  objectAtIndex:0];
        window.clipsToBounds = YES;
        [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleBlackOpaque];
        
        window.bounds = CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
        window.frame =  CGRectMake(0, 20, window.frame.size.width, window.frame.size.height);
    }

    [controller dismissViewControllerAnimated:YES completion:nil];
    [controller release];
}

@end
