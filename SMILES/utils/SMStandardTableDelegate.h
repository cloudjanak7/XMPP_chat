//
//  SMStandardTableDelegate.h
//  SMILES
//
//  Created by asepmoels on 7/25/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SMStandardTableFieldName        @"name"
#define SMStandardTableFieldPhoto       @"photo"

@class SMStandardTableDelegate;

@protocol SMStandarTalbePickingDelegate <NSObject>

-(void)SMStandarTable:(SMStandardTableDelegate *)table didPickedItem:(NSDictionary *)dict;

@end

@interface SMStandardTableDelegate : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSArray *data;
@property (nonatomic, unsafe_unretained) id<SMStandarTalbePickingDelegate> delegate;

@end
