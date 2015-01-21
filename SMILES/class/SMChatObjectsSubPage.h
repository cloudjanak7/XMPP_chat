//
//  SMChatObjectsSubPage.h
//  SMILES
//
//  Created by asepmoels on 7/22/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMChatObjectsSubPage;

@protocol SMChatObjectsSubPagaDelegate <NSObject>

-(void)chatObjectPage:(SMChatObjectsSubPage *)subpage didSelectItem:(NSDictionary *)dict;

@end

@interface SMChatObjectsSubPage : UIViewController

-(void)reloadData;

@property (nonatomic, copy) NSString *user;
@property (nonatomic, unsafe_unretained) id<SMChatObjectsSubPagaDelegate>delegate;

@end
