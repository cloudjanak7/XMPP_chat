//
//  SMFriendsCell.m
//  SMILES
//
//  Created by asepmoels on 7/9/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMRecentChatCell.h"

@implementation SMRecentChatCell

@synthesize avatar, name, recentMessage, time, unreadNum, recentMessageBG, check;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
