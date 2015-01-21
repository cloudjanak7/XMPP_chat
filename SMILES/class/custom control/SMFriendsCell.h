//
//  SMFriendsCell.h
//  SMILES
//
//  Created by asepmoels on 7/9/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMFriendsCell : UITableViewCell

@property (nonatomic, unsafe_unretained) IBOutlet UIImageView *avatar;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *name;
@property (nonatomic, unsafe_unretained) IBOutlet UILabel *status;
@property (nonatomic, unsafe_unretained) IBOutlet UIView *bg;

@end
