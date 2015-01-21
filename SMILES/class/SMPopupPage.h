//
//  SMPopupPage.h
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    SMPopupTypeInviteFriend,
    SMPopupTypeInviteOther,
    SMPopupTypeInviteGroup,
    SMPopupTypeAdminBroadcast
}SMPopupType;

@class SMPopupPage;

@protocol SMPopupPageDelegate <NSObject>
-(void)smpopupView:(SMPopupPage *)viewController didSelectItemAtIndex:(NSInteger)index info:(NSDictionary *)info;
@end

@interface SMPopupPage : UIViewController

-(id)initWithType:(SMPopupType)type;
-(void)show;

@property (nonatomic, unsafe_unretained) id<SMPopupPageDelegate> delegate;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic) NSInteger tag;
@property (nonatomic, retain) NSString *message;

@end
