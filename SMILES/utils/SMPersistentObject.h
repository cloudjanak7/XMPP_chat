//
//  SMPersistentObject.h
//  SMILES
//
//  Created by asepmoels on 7/22/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    StickerTypeStickerGroup,
    StickerTypeIkoniaGroup,
    StickerTypeStickerItems,
    StickerTypeIkoniaItems,
    StickerTypeEmoticons,
    StickerTypeAttachment
}StickerType;

#define kTableNameStickerGroup      @"stickergroups"
#define kTableNameStickerItems      @"stickeritem"
#define kTableNameContacts          @"contact"
#define kTableNameVisitor           @"visitor"
#define kTableNameFriendsUpdate     @"friendsupdate"
#define kTableNameMessageBackup     @"messagebackup"
#define kTableNameResendMessage     @"resendmessage"
#define kTableNameOnlyInviteAdmin   @"onlyinviteadmin"

#define kTableNameEmoticon          @"emoticon"

//messagebackup table fields
#define kTableFieldSender           @"sender"
#define kTableFieldReciever         @"reciever"
#define kTableFieldStatus           @"status"
#define kTableFieldMessage          @"message"

#define kTableFieldID               @"id"
#define kTableFieldName             @"name"
#define kTableFieldDesc             @"desc"
#define kTableFieldPrice            @"price"
#define kTableFieldThumbnail        @"thumb"
#define kTableFieldAllow            @"allow"
#define kTableFieldUser             @"user"
#define kTableFieldType             @"type"
#define kTableFieldGroup            @"groupid"
#define kTableFieldEmail            @"email"
#define kTableFieldPhone            @"phone"
#define kTableFieldViewed           @"viewed"
#define kTableFieldDate             @"datetime"

#define kTableFieldPlain            @"plain"
#define kTableFieldImage            @"image"
#define kTableFieldUnicode          @"unicode"

@protocol SMPersistentObjectObserver <NSObject>
-(void)didFinishFetch:(NSDictionary *)info;
@end

@interface SMPersistentObject : NSObject

+(SMPersistentObject *)sharedObject;

-(void)fetchStickerGroupWithType:(StickerType)type forUser:(NSString *)user observer:(id <SMPersistentObjectObserver>)observer;
-(void)fetchStickerWithType:(StickerType)type groupID:(NSInteger)group forUser:(NSString *)user observer:(id<SMPersistentObjectObserver>)observer;

-(void)collectAdressBookDataForUser:(NSString *)user;
-(NSArray *)getRandomContact:(NSInteger)count;
-(NSArray *)contactArrayWithEmail;
-(NSArray *)contactArrayWithPhone;

-(void)addNewVisitor:(NSString *)username;
-(NSMutableArray *)getVisitors:(NSInteger)num;
-(void)clearUnviewedVisitor;
-(NSInteger)getUnviewedVisitorNum;

-(void)addFriendsUpdate:(NSString *)name message:(NSString *)msg;
-(void)clearUnviewedFriendUpdate;
-(NSMutableArray *)getFriendsUpdate:(NSInteger)num;
-(NSInteger)getUnviewedFriendUpdate;

-(NSArray *)emoticonsGrouped:(BOOL)grouped;

- (NSMutableArray *)fetchResendMessage:(NSString *)sender receiver:(NSString *)receiver;
- (NSMutableDictionary *)fetchResendMessageById:(int)nID;
- (int)addResendMessage:(NSMutableDictionary *)messageDict;
- (void)deleteResendMessage:(int)resendMessageId;

- (NSDictionary *)fetchOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare;
- (void)addOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare adminUser:(NSString *)adminUserName onlyInviteAdmin:(BOOL)onlyInviteAdmin;
- (void)deleteOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare;

@end
