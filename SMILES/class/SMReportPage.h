//
//  SMReportPage.h
//  SMILES
//
//  Created by Jie Meng on 1/25/14.
//  Copyright (c) 2014 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMReportPage : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (assign, nonatomic) NSString *sSender;
@property (assign, nonatomic) NSString *sSuspect;

@end
