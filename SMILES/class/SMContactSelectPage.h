//
//  SMContactSelectPage.h
//  SMILES
//
//  Created by asepmoels on 8/1/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SMContactSelectPageDelegate

-(void)didSelectContact:(NSDictionary *)contact;

@end

@interface SMContactSelectPage : UIViewController

@property (nonatomic, retain) NSArray *data;
@property (nonatomic, retain) NSArray *aryRecommend;
@property (nonatomic) BOOL isEmail;
@property (nonatomic) BOOL multiselect;
@property (nonatomic, unsafe_unretained) id<SMContactSelectPageDelegate> singleSelectDelegate;

@end
