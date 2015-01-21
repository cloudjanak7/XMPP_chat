//
//  SMVisitorCell.m
//  SMILES
//
//  Created by asepmoels on 8/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMVisitorCell.h"

@implementation SMVisitorCell

@synthesize foto, name, time, bg;

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
