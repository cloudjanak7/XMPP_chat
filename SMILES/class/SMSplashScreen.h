//
//  SMSplashScreen.h
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SMSplashScreen : UIViewController{
    BOOL shouldCheckConnection;
}

-(void)checkConnection;
-(BOOL)shouldCheckConnection;

@end
