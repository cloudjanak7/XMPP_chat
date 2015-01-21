//
//  XMPPMessage+MyDelivery.m
//  SMILES
//
//  Created by asepmoels on 7/18/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "XMPPMessage+MyCustom.h"

@implementation XMPPMessage (MyCustom)

-(BOOL)isDelivered{
    NSString *str = [self attributeForName:@"flag"].stringValue;
    if([str isEqualToString:@"1"])
        return YES;
    
    return NO;
}

-(void)setDelivered:(BOOL)_delivered{
    [self addAttribute:[DDXMLNode attributeWithName:@"flag" stringValue:_delivered?@"1":@"0"]];
}

-(BOOL)isImageMessage{
    if(([self.body rangeOfString:kMessageKeyIkonia].length > 0 || [self.body rangeOfString:kMessageKeySticker].length > 0))
        return YES;
    
    if([self.body rangeOfString:kMessageKeyFile].length > 0){
        NSDictionary *dict = [self parsedMessage];
        if([[dict valueForKey:@"type"] isEqualToString:@"CONTACT"]){
            return NO;
        }else{
            return YES;
        }
    }
    
    return NO;
}

-(BOOL)isGroupMessage{
    if([self.from.domain isEqualToString:@"group.lb1.smilesatme.com"] || [self.from.domain isEqualToString:@"room.lb1.smilesatme.com"])
        return YES;
    
    return NO;
}

-(BOOL)isBroadcastMessage{
    if([self.body rangeOfString:kMessageKeyBroadcast].length > 0)
        return YES;
    
    return NO;
}

-(BOOL)isLocationMessage{
    if([self.body rangeOfString:kMessageKeyLocation].length > 0)
        return YES;
    
    return NO;
}

-(BOOL)isAttentionMessage2{
    if([self.body rangeOfString:kMessageKeyAttention].length > 0)
        return YES;
    
    return NO;
}

-(BOOL)isFileMessage{
    if([self.body rangeOfString:kMessageKeyFile].length > 0)
        return YES;
    
    return NO;
}

-(BOOL)isContactMessage{
    if([self.body rangeOfString:@"F1L3K03@TYPE:CONTACT"].length > 0)
        return YES;
    
    return NO;
}

-(NSDictionary *)parsedMessage{
    NSString *msg = self.body;
    
    if([self isBroadcastMessage]){
        msg = [msg stringByReplacingOccurrencesOfString:kMessageKeyBroadcast withString:@""];
        return [NSDictionary dictionaryWithObjectsAndKeys:msg, @"message", nil];
    }else if([self isLocationMessage]){
        msg = [msg stringByReplacingOccurrencesOfString:kMessageKeyLocation withString:@""];
        NSArray *arr = [msg componentsSeparatedByString:@"/"];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        for(NSString *str in arr){
            if([str rangeOfString:@"LAT:"].length > 0){
                [dict setValue:[str stringByReplacingOccurrencesOfString:@"LAT:" withString:@""] forKey:@"latitude"];
            }else if([str rangeOfString:@"LONG:"].length > 0){
                [dict setValue:[str stringByReplacingOccurrencesOfString:@"LONG:" withString:@""] forKey:@"longitude"];
            }
        }
        return dict;
    }else if([self isContactMessage]){
        msg = [msg stringByReplacingOccurrencesOfString:@"F1L3K03@TYPE:CONTACT/NAME" withString:@""];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        NSArray *arr = [msg componentsSeparatedByString:@"/NUMBER:"];
        [dict setValue:[arr objectAtIndex:0] forKey:@"name"];
        [dict setValue:[arr objectAtIndex:1] forKey:@"phone"];
        
        return dict;
    }else if([self isFileMessage]){
        msg = [msg stringByReplacingOccurrencesOfString:kMessageKeyFile withString:@""];
        
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        NSArray *arr = [msg componentsSeparatedByString:@"/DESC:"];
        NSString *type = [[arr objectAtIndex:0] stringByReplacingOccurrencesOfString:@"TYPE:" withString:@""];
        [dict setValue:type forKey:@"type"];
        
        arr = [[arr objectAtIndex:1] componentsSeparatedByString:@"/URL:"];
        [dict setValue:[arr objectAtIndex:0] forKey:@"desc"];
        
        arr = [[arr objectAtIndex:1] componentsSeparatedByString:@"/THUMB:"];
        NSString *url = [arr objectAtIndex:0];
        if([url rangeOfString:@"http:"].length < 1)
            url = [@"http://api.smilesatme.com/" stringByAppendingString:url];
        [dict setValue:url forKey:@"url"];
        
        if(arr.count > 1){
            url = [arr objectAtIndex:1];
            if([url rangeOfString:@"http:"].length < 1)
                url = [@"http://api.smilesatme.com/" stringByAppendingString:url];
            [dict setValue:url forKey:@"thumb"];
        }else{
            [dict setValue:url forKey:@"thumb"];
        }
        
        return dict;
    }
    
    return nil;
}

-(NSString *)typeStr{
    if([self.body rangeOfString:kMessageKeyIkonia].length > 0)
        return @"ikonia";
    if([self.body rangeOfString:kMessageKeySticker].length > 0)
        return @"sticker";
    if([self.body rangeOfString:kMessageKeyBroadcast].length > 0)
        return @"broadcast";
    if([self.body rangeOfString:kMessageKeyLocation].length > 0)
        return @"location";
    if([self isContactMessage])
        return @"contact";
    if([self.body rangeOfString:kMessageKeyFile].length > 0)
        return @"file";
    if([self.body rangeOfString:kMessageKeyAttention].length > 0)
        return @"attention";
    return nil;
}

-(void)setImageMessage:(BOOL)imageMessage{
    
}

-(NSURL *)imageURL{
    NSArray *comps = [self.body componentsSeparatedByString:@"@"];
    NSMutableArray *arrTemp = [NSMutableArray arrayWithArray:comps];
    [arrTemp removeObjectAtIndex:0];
    NSString *strUrl = [arrTemp componentsJoinedByString:@""];
    return [NSURL URLWithString:strUrl];
}

@end
