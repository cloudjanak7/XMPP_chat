//
//  SMHeaderContactView.m
//  SMILES
//
//  Created by asepmoels on 7/11/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMHeaderContactView.h"

@implementation SMHeaderContactView

@synthesize arrowImage, titleLabel, reuseIdentifier, bgView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.reuseIdentifier = @"SMHeaderContactView";
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.reuseIdentifier = @"SMHeaderContactView";
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
