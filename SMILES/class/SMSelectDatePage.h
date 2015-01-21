//
//  SMSelectDatePage.h
//  SMILES
//
//  Created by asepmoels on 7/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMSelectDatePage;

@protocol SMSelectDatePageDelegate <NSObject>

-(void)SMSelectDatePage:(SMSelectDatePage *)page didSelectDate:(NSDate *)date;

@end

@interface SMSelectDatePage : UIViewController

-(void)setDate:(NSDate *)date;

@property (nonatomic, unsafe_unretained) id<SMSelectDatePageDelegate>delegate;

@end
