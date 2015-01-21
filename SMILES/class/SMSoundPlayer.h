//
//  SMSoundPlayer.h
//  SMILES
//
//  Created by wang chenglei on 3/28/14.
//  Copyright (c) 2014 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMSoundPlayer : UIViewController

@property (strong, nonatomic) NSData *soundData;

-(void)show;
-(void)hide;
-(void)reset;

@end
