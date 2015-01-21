//
//  SMSoundRecorder.h
//  SMILES
//
//  Created by asepmoels on 8/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SMSoundRecorderDelegate <NSObject>

-(void)soundDidRecorded;

@end

@interface SMSoundRecorder : UIViewController

@property (nonatomic, retain) NSData *data;
@property (nonatomic, unsafe_unretained) id<SMSoundRecorderDelegate>delegate;

-(void)show;
-(void)hide;
-(void)reset;

@end
