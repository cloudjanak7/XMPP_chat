//
//  SMAppConfig.m
//  SMILES
//
//  Created by asepmoels on 7/4/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMAppConfig.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

static SMAppConfig *config = nil;

@implementation SMAppConfig

@synthesize deviceToken, deviceIMEI, carrier, latitudeStr, longitudeStr;

+(SMAppConfig *)sharedConfig{
    if(!config){
        config = [[SMAppConfig alloc] init];
        config.deviceIMEI = [SMAppConfig getImei];
    }
    
    return config;
}

- (void)dealloc
{
    [deviceIMEI release];
    [deviceToken release];
    [latitudeStr release];
    [longitudeStr release];
    [super dealloc];
}

+(NSString *)getImei{
    NSString *udid = nil;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0"))
        udid = [UIDevice currentDevice].identifierForVendor.UUIDString;
//    else
//        udid = [UIDevice currentDevice].uniqueIdentifier;
    
    return udid ;
}

-(NSString *)carrier{
    CTTelephonyNetworkInfo *netinfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *currentcarrier = [netinfo subscriberCellularProvider];
    NSString *carrierName = currentcarrier.carrierName;
    
    if([currentcarrier.mobileCountryCode isEqualToString:@"510"]){
        switch ([currentcarrier.mobileNetworkCode intValue]) {
            case 0:
                carrierName = @"PSN";
                break;
            case 1:
                carrierName = @"INDOSAT";
                break;
            case 3:
                carrierName = @"StarOne";
                break;
            case 7:
                carrierName = @"TelkomFlexi";
                break;
            case 8:
                carrierName = @"AXIS";
                break;
            case 9:
                carrierName = @"SMART";
                break;
            case 10:
                carrierName = @"TELKOMSEL";
                break;
            case 20:
                carrierName = @"TELKOMMobile";
                break;
            case 21:
                carrierName = @"IM3";
                break;
            case 27:
                carrierName = @"Ceria";
                break;
            case 28:
                carrierName = @"Fren/Hepi";
                break;
            case 89:
                carrierName = @"3";
                break;
            case 99:
                carrierName = @"ESIA";
                break;
            case 995:
            case 996:
                carrierName = @"Komselindo";
                break;
                
            default:
                break;
        }
    }
    
    [netinfo release];
    
    return carrierName;
}

-(NSString *)deviceToken{
    return [[[deviceToken stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end
