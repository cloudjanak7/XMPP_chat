//
//  SMMyUserProfile.m
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMMyUserProfile.h"
#import "ASIFormDataRequest.h"
#import "SMAppConfig.h"

static SMMyUserProfile *sharedObject = nil;

@interface SMMyUserProfile(){
    NSString *myPath;
}
@end

@implementation SMMyUserProfile

@synthesize username, admin, userId, birthday, email, fullname, gender, status, avatarThumb, avatar, photoCount, photoList, groups, rooms, chatBackgrounds, chatFontSize;

- (void)dealloc
{
    [myPath release];
    [username release];
    [userId release];
    [birthday release];
    [email release];
    [fullname release];
    [gender release];
    [status release];
    [avatarThumb release];
    [avatar release];
    [photoList release];
    [groups release];
    [rooms release];
    [chatBackgrounds release];
    [super dealloc];
}

-(id)initWithUsername:(NSString *)withusername{
    self = [super init];
    if(self){
        NSArray *arr = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [arr lastObject];
        myPath = [[path stringByAppendingPathComponent:withusername] copy];
        username = [withusername copy];
    }
    return self;
}

+(SMMyUserProfile *)curentProfileForUsername:(NSString *)username{
    if(!sharedObject){
        sharedObject = [[SMMyUserProfile alloc] initWithUsername:username];
    }
    
    if(![sharedObject.username isEqualToString:username]){
        [sharedObject release];
        sharedObject = [[SMMyUserProfile alloc] initWithUsername:username];
    }
    
    return sharedObject;
}

-(void)save{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:self.username forKey:@"username"];
    [data setValue:[NSNumber numberWithBool:self.isAdmin] forKey:@"admin"];
    [data setValue:self.userId forKey:@"userid"];
    [data setValue:self.birthday forKey:@"birthday"];
    [data setValue:self.gender forKey:@"gender"];
    [data setValue:self.email forKey:@"email"];
    [data setValue:self.fullname forKey:@"fullname"];
    [data setValue:self.status forKey:@"status"];
    [data setValue:self.avatar forKey:@"avatar"];
    [data setValue:self.avatarThumb forKey:@"avatarThumb"];
    [data setValue:[NSNumber numberWithInt:(int)self.photoCount] forKey:@"photoCount"];
    [data setValue:self.photoList forKey:@"photoList"];
    [data setValue:self.groups forKey:@"groups"];
    [data setValue:self.rooms forKey:@"rooms"];
    [data setValue:self.chatBackgrounds forKey:@"chatbgs"];
    [data setValue:[NSNumber numberWithInt:(int)self.chatFontSize] forKey:@"chatfontSize"];
    [data writeToFile:myPath atomically:YES];
}

-(void)load{
    NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:myPath];
    self.username = [data valueForKey:@"username"];
    self.admin = [[data valueForKey:@"admin"] boolValue];
    self.userId = [data valueForKey:@"userid"];
    self.birthday = [data valueForKey:@"birthday"];
    self.gender = [data valueForKey:@"gender"];
    self.email = [data valueForKey:@"email"];
    self.fullname = [data valueForKey:@"fullname"];
    self.status = [data valueForKey:@"status"];
    self.avatar = [data valueForKey:@"avatar"];
    self.avatarThumb = [data valueForKey:@"avatarThumb"];
    self.photoCount = [[data valueForKey:@"photoCount"] integerValue];
    self.photoList = [data valueForKey:@"photoList"];
    self.groups = [data valueForKey:@"groups"];
    self.rooms = [data valueForKey:@"rooms"];
    self.chatFontSize = [[data valueForKey:@"chatfontSize"] integerValue];
    self.chatBackgrounds = [NSMutableDictionary dictionaryWithDictionary:[data valueForKey:@"chatbgs"]];
    
    if(self.chatFontSize < 8)
        self.chatFontSize = 13;
}

-(void)broadcast:(BroadcastType)type{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLBroadcastUpdate]];
    
    NSString *action = @"";
    
    switch (type) {
        case BroadcastTypeAvatar:{
            action = [NSString stringWithFormat:@"change %@ avatar", [self.gender isEqualToString:@"pria"]?@"his":@"her"];
        }
            break;
        case BroadcastTypeStatus:{
            action = [NSString stringWithFormat:@"change %@ status", [self.gender isEqualToString:@"pria"]?@"his":@"her"];
        }
            break;
        case BroadcastTypeAddPhoto:{
            action = @"upload new photo";
        }
            break;
            
        default:
            break;
    }
    
    NSString *message = [NSString stringWithFormat:@"%@ has %@", self.username, action];
    
    [request setPostValue:self.username forKey:@"username"];
    [request setPostValue:message forKey:@"message"];
    [request startAsynchronous];
    [request setCompletionBlock:^{
        NSLog(@"%@", [request responseString]);
    }];
}

-(void)visit:(NSString *)targetusername{
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLvisit]];
    [request setPostValue:self.username forKey:@"username"];
    [request setPostValue:targetusername forKey:@"targetname"];
    [request startAsynchronous];
}

@end
