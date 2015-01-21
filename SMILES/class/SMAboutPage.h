//
//  SMAboutPage.h
//  SMILES
//
//  Created by asepmoels on 7/25/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PageTypeAbout = 1,
    PageTypeToS = 2,
    PageTypePrivacy = 3
}PageType;

@interface SMAboutPage : UIViewController

@property (nonatomic) PageType pageType;

@end
