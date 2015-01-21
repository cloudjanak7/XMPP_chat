//
//  SMStandardTextField.m
//  SMILES
//
//  Created by asepmoels on 7/11/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMStandardTextField.h"

#define kTextPadding        10

@implementation SMStandardTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
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
    self.borderStyle = UITextBorderStyleNone;
    UIView *vLeft = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kTextPadding, self.frame.size.height)];
    vLeft.backgroundColor = [UIColor clearColor];
    
    UIView *vRight = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width-kTextPadding, 0, kTextPadding, self.frame.size.height)];
    vRight.backgroundColor = [UIColor clearColor];
    
    self.leftView = vLeft;
    self.leftViewMode = UITextFieldViewModeAlways;
    self.leftView = vRight;
    self.leftViewMode = UITextFieldViewModeAlways;
}

-(BOOL)becomeFirstResponder{
    self.background = [UIImage imageNamed:@"text-field-focus.png"];
    return [super becomeFirstResponder];
}

-(BOOL)resignFirstResponder{
    self.background = [UIImage imageNamed:@"text-field.png"];
    return [super resignFirstResponder];
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
