//
//  SMChatCell.h
//  SMILES
//
//  Created by asepmoels on 7/14/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>
@class EGOImageView;

typedef enum {
    SMMessageTypeText,
    SMMessageTypeImage
} SMMessageType;

@interface SMChatCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *msgSenderName;
@property (nonatomic, weak) IBOutlet UILabel *message;
@property (nonatomic, weak) IBOutlet UIImageView *messageBG;
@property (nonatomic, weak) IBOutlet UIView *timestampContainer;
@property (nonatomic, weak) IBOutlet UIImageView *messageSent;
@property (nonatomic, weak) IBOutlet UILabel *messagetimestamp;
@property (nonatomic, weak) IBOutlet EGOImageView *messageImage;
@property (nonatomic) SMMessageType type;
@property (nonatomic) BOOL outgoing;
@property (nonatomic, weak) IBOutlet UIButton *retryBtn;
@property (nonatomic, weak) IBOutlet UIImageView *videoPlayImgView;

@end
