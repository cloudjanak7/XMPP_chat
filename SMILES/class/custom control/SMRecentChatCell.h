//
//  SMFriendsCell.h
//  SMILES
//
//  Created by asepmoels on 7/9/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMRecentChatCell : UITableViewCell

@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *avatar;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *name;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *recentMessage;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *recentMessageBG;
@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *check;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *unreadNum;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *time;

@end
