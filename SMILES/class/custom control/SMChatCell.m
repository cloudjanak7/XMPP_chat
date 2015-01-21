//
//  SMChatCell.m
//  SMILES
//
//  Created by asepmoels on 7/14/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMChatCell.h"
#import "EGOImageView.h"

@interface SMChatCell(){
    UIImage *chatboxMe;
    UIImage *chatboxFriend;
}

@end

@implementation SMChatCell

@synthesize message, messageBG, messageSent, messagetimestamp, timestampContainer, type, messageImage, outgoing;
@synthesize retryBtn, videoPlayImgView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup{
    UIImage *cf = [UIImage imageNamed:@"chat-box-friend.png"];
    UIImage *cm = [UIImage imageNamed:@"chat-box-elu.png"];
    
    [cf stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    if([cf respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]){
        chatboxFriend = [cf resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15) resizingMode:UIImageResizingModeStretch];
        chatboxMe = [cm resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15) resizingMode:UIImageResizingModeStretch];
    }else{
        chatboxFriend = [cf stretchableImageWithLeftCapWidth:15 topCapHeight:15.];
        chatboxMe = [cm stretchableImageWithLeftCapWidth:15. topCapHeight:15.];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)setType:(SMMessageType)_type{
    if(_type == SMMessageTypeText){
        self.messageImage.hidden = YES;
//        self.messageBG.hidden = NO;
        self.message.hidden = NO;
        self.videoPlayImgView.hidden = YES;
    }else if(_type == SMMessageTypeImage){
        self.messageImage.hidden = NO;
//        self.messageBG.hidden = YES;
        self.message.hidden = YES;
    }
}

-(void)setOutgoing:(BOOL)_outgoing{
    if(_outgoing){
        self.messageBG.image = chatboxFriend;
        self.messageSent.hidden = NO;
    }else{
        self.messageBG.image = chatboxMe;
        self.messageSent.hidden = YES;
    }
}

@end
