//
//  SMMyUserProfile.h
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    BroadcastTypeAvatar,
    BroadcastTypeStatus,
    BroadcastTypeAddPhoto
}BroadcastType;

@interface SMMyUserProfile : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, getter = isAdmin) BOOL admin;
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSDate *birthday;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *fullname;
@property (nonatomic, retain) NSString *gender;
@property (nonatomic, retain) NSString *status;
@property (nonatomic, retain) NSString *avatarThumb;
@property (nonatomic, retain) NSString *avatar;
@property (nonatomic) NSInteger photoCount;
@property (nonatomic, retain) NSMutableArray *photoList;
@property (nonatomic, retain) NSMutableArray *groups;
@property (nonatomic, retain) NSMutableArray *rooms;
@property (nonatomic, retain) NSMutableDictionary *chatBackgrounds;
@property (nonatomic) NSInteger chatFontSize;

+(SMMyUserProfile *)curentProfileForUsername:(NSString *)username;

-(void)save;
-(void)load;
-(void)broadcast:(BroadcastType)type;
-(void)visit:(NSString *)username;

@end
