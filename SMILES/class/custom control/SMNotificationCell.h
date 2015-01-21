//
//  SMVisitorCell.h
//  SMILES
//
//  Created by asepmoels on 8/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMNotificationCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *foto;
@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *time;
@property (nonatomic, weak) IBOutlet UILabel *sub;
@property (nonatomic, weak) IBOutlet UIView *bg;

@end
