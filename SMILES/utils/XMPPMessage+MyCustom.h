//
//  XMPPMessage+MyDelivery.h
//  SMILES
//
//  Created by asepmoels on 7/18/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "XMPPMessage.h"

#define kMessageKeyIkonia       @"1K0N14K03@"
#define kMessageKeySticker      @"5T1CK3RK03@"
#define kMessageKeyLocation     @"L0C4T10NK03@"
#define kMessageKeyBroadcast    @"BR04DC4STK03@"
#define kMessageKeyFile         @"F1L3K03@"
#define kMessageKeyAttention    @"4T3NT10NK03@"

@interface XMPPMessage (MyCustom)

-(NSString *)typeStr;
-(NSDictionary *)parsedMessage;
-(NSURL *)imageURL;

@property (nonatomic, getter = isDelivered) BOOL delivered;
@property (nonatomic, getter = isImageMessage, readonly) BOOL imageMessage;
@property (nonatomic, getter = isGroupMessage, readonly) BOOL groupMessage;
@property (nonatomic, getter = isBroadcastMessage, readonly) BOOL broadcastMessage;
@property (nonatomic, getter = isLocationMessage, readonly) BOOL locationMessage;
@property (nonatomic, getter = isAttentionMessage2, readonly) BOOL attentionMessage2;
@property (nonatomic, getter = isFileMessage, readonly) BOOL fileMessage;
@property (nonatomic, getter = isContactMessage, readonly) BOOL contactMessage;

@end
