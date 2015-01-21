//
//  SMChatSettingPage.h
//  SMILES
//
//  Created by asepmoels on 8/16/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMChatSettingPage : UIViewController

@property (nonatomic, copy) NSString *friendBare;
@property (nonatomic, unsafe_unretained) UIImageView *backgroundToChange;
@property (nonatomic, unsafe_unretained) NSMutableArray *chatDataToChange;
@property (nonatomic, unsafe_unretained) UITableView *tableToRefresh;

@end
