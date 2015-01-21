//
//  SMStandardTableDelegate.m
//  SMILES
//
//  Created by asepmoels on 7/25/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMStandardTableDelegate.h"

@implementation SMStandardTableDelegate

@synthesize data, delegate;

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"standardtablepopoupcell"];
    
    if(!cell){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"standardtablepopoupcell"] autorelease];
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    NSDictionary *dict = [data objectAtIndex:indexPath.row];
    cell.imageView.image = [dict valueForKey:SMStandardTableFieldPhoto];
    cell.textLabel.text = [dict valueForKey:SMStandardTableFieldName];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(delegate && [delegate respondsToSelector:@selector(SMStandarTable:didPickedItem:)]){
        NSDictionary *dict = [data objectAtIndex:indexPath.row];
        [delegate SMStandarTable:self didPickedItem:dict];
    }
}

@end
