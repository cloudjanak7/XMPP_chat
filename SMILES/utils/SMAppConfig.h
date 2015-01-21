//
//  SMAppConfig.h
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kURLMain                @"http://api.smilesatme.com/"
#define kURLConfiguration       kURLMain @"configuration"
#define kURLCountryCode         kURLMain @"countrycodes.xml"
#define kURLVerifyCode          kURLMain @"user/verify_phone"
#define kURLRegister            kURLMain @"user/register"
#define kURLStickerPackages     kURLMain @"sticker/packages"
#define kURLStickerItems        kURLMain @"sticker/package_detail"
#define kURLGetProfile          kURLMain @"user/get_profile"
#define kURLUpdateProfile       kURLMain @"user/update_profile"
#define kURLUploadAvatar        kURLMain @"user/upload_avatar"
#define kURLGetText             kURLMain @"user/get_text"
#define kURLStickerUse          kURLMain @"sticker/use"
#define kURLStickerDownload     kURLMain @"sticker/download"
#define kURLFriendRecommend     kURLMain @"user/upload_contacts"
#define kURLUserSearch          kURLMain @"user/search"
#define kURLUserLogin           kURLMain @"user/login"
#define kURLUserLogout          kURLMain @"user/logout"
#define kURLUserPhotos          kURLMain @"user/photo/get"
#define kURLUserUploadPhoto     kURLMain @"user/photo/upload"
#define kURLvisit               kURLMain @"user/visit"
#define kURLUserDelete          kURLMain @"user/delete"
#define kURLResetPassword       kURLMain @"user/reset_password"
#define kURLChangePassword      kURLMain @"user/change_password"
#define kURLPhotoDelete         kURLMain @"user/photo/delete"
#define kURLFriendAdd           kURLMain @"friend/add"
#define kURLFriendApprove       kURLMain @"friend/approve"
#define kURLFriendList          kURLMain @"friend/list/active"
#define kURLFriendDelete        kURLMain @"friend/delete"
#define kURLFriendBlock         kURLMain @"friend/block"
#define kURLFriendBlockList     kURLMain @"friend/list/block"
#define kURLBroadcastUpdate     kURLMain @"user/broadcast_myupdate"
#define kURLWakeup              kURLMain @"user/wakeup"
#define kURLAdminBroadcast      kURLMain @"user/admin_broadcast"
#define kURLRightMenu           kURLMain @"user/right_menu"
#define kURLUploadFiles         kURLMain @"files"
#define kURLReportUser          kURLMain @"user/report"

#define kvCardDesGroupList      @"GROUP_LIST"
#define kvCardDesRoomList       @"ROOM_LIST"
#define kvCardDesId             @"id"
#define kvCardDesTitle          @"title"
#define kvCardDesJid            @"desc"
#define kvCardDesThumb          @"thumb"
#define kvCardDesOnlyInviteAdmin @"onlyInviteAdmin"

@interface SMAppConfig : NSObject
+(SMAppConfig *)sharedConfig;

@property (nonatomic, copy) NSString *deviceToken;
@property (nonatomic, copy) NSString *deviceIMEI;
@property (nonatomic, readonly) NSString *carrier;
@property (nonatomic, copy) NSString *longitudeStr;
@property (nonatomic, copy) NSString *latitudeStr;

@end
