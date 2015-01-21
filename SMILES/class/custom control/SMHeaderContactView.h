//
//  SMHeaderContactView.h
//  SMILES
//
//  Created by asepmoels on 7/11/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMHeaderContactView : UIView

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *arrowImage;
@property (nonatomic, weak) IBOutlet UIView *bgView;
@property (nonatomic, copy) NSString *reuseIdentifier;

@end
