//
//  SMPhotosPage.h
//  SMILES
//
//  Created by asepmoels on 7/28/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMPhotosPage : UIViewController

@property (nonatomic, unsafe_unretained) NSMutableArray *photoData;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *targetname;
@property (nonatomic, retain) NSString *displayName;

@end
