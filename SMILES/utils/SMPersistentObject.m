//
//  SMPersistentObject.m
//  SMILES
//
//  Created by asepmoels on 7/22/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMPersistentObject.h"
#import <sqlite3.h>
#import "SMAppConfig.h"
#import "ASIFormDataRequest.h"
#import "JSON.h"
#import <AddressBook/AddressBook.h>

static SMPersistentObject *sharedObj = nil;

@interface SMPersistentObject(){
    NSString *databasePath;
}

@end

@interface SMPersistentObject(){
    NSOperationQueue *queue;
}

@end

@implementation SMPersistentObject

+(SMPersistentObject *)sharedObject{
    if(!sharedObj){
        sharedObj = [[SMPersistentObject alloc] init];
    }
    return sharedObj;
}

- (void)dealloc
{
    [databasePath release];
    [queue release];
    [super dealloc];
}

-(id)init{
    self = [super init];
    if(self){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [[paths lastObject] stringByAppendingPathComponent:@"shareddata.sqlite"];
        databasePath = [docDir copy];
        
        [self createDatabase];
        
        queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

-(void)createDatabase{
    sqlite3 *database;
    if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK){
        char *err;
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ INT, %@ TEXT, %@ TEXT, %@ REAL, %@ TEXT, %@ TINYINT, %@ TEXT, %@ INT)", kTableNameStickerGroup, kTableFieldID, kTableFieldName, kTableFieldDesc, kTableFieldPrice, kTableFieldThumbnail, kTableFieldAllow, kTableFieldUser, kTableFieldType];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ INT, %@ INT, %@ TEXT, %@ TEXT, %@ INT)", kTableNameStickerItems, kTableFieldID, kTableFieldGroup, kTableFieldThumbnail, kTableFieldUser, kTableFieldType];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ TEXT, %@ TEXT, %@ TEXT)", kTableNameContacts, kTableFieldName, kTableFieldPhone, kTableFieldEmail];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ TEXT, %@ REAL, %@ TINYINT)", kTableNameVisitor, kTableFieldName, kTableFieldDate, kTableFieldViewed];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ TEXT, %@ TEXT, %@ REAL, %@ TINYINT)", kTableNameFriendsUpdate, kTableFieldName, kTableFieldDesc, kTableFieldDate, kTableFieldViewed];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (%@ TEXT, %@ TEXT,%@ TEXT,%@ TEXT, %@ REAL)", kTableNameMessageBackup , kTableFieldSender, kTableFieldReciever,kTableFieldMessage, kTableFieldStatus, kTableFieldDate];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
            NSLog(@"error");
        }

        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (id INTEGER PRIMARY KEY AUTOINCREMENT, message TEXT, outgoing INT, time DOUBLE, text TEXT, sender TEXT, receiver TEXT)", kTableNameResendMessage];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
            NSLog(@"error");
        }
        
        sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS '%@' (id INTEGER PRIMARY KEY AUTOINCREMENT, groupname TEXT, groupbare TEXT, adminusername TEXT, onlyinviteadmin INT)", kTableNameOnlyInviteAdmin];
        if (sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK){
            NSLog(@"error");
        }
    }
    sqlite3_close (database);
}

-(NSMutableArray *)databaseFetchStickerGroupWithType:(StickerType)type forUser:(NSString *)user{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@='1' AND %@='%@' AND %@='%d'", kTableNameStickerGroup, kTableFieldAllow, kTableFieldUser, user, kTableFieldType, type];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                char *thumb = (char *)sqlite3_column_text(statement, 4);
                int _id = sqlite3_column_int(statement, 0);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                [row setValue:[NSNumber numberWithInt:_id] forKey:kTableFieldID];
                [row setValue:[NSString stringWithUTF8String:thumb] forKey:kTableFieldThumbnail];
                
                [data addObject:row];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return data;
}

-(NSMutableArray *)databaseFetchStickerWithType:(StickerType)type groupID:(NSInteger)group forUser:(NSString *)user{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@='%d' AND %@='%@' AND %@='%d'", kTableNameStickerItems, kTableFieldGroup, (int)group, kTableFieldUser, user, kTableFieldType, type];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                char *thumb = (char *)sqlite3_column_text(statement, 2);
                int _id = sqlite3_column_int(statement, 0);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                [row setValue:[NSNumber numberWithInt:_id] forKey:kTableFieldID];
                [row setValue:[NSString stringWithUTF8String:thumb] forKey:kTableFieldThumbnail];
                
                [data addObject:row];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return data;
}

-(void)fetchStickerGroupWithType:(StickerType)type forUser:(NSString *)user observer:(id<SMPersistentObjectObserver>)observer{
    __block NSArray *result = [self databaseFetchStickerGroupWithType:type forUser:user];
    
    if(result.count > 0){
        [observer didFinishFetch:[NSDictionary dictionaryWithObjectsAndKeys:result, @"result", [NSNumber numberWithInt:type], @"type", nil]];
    }else{
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLStickerPackages]];
        [request setPostValue:type==StickerTypeStickerGroup?@"sticker":@"ikonia" forKey:@"type"];
        [request setPostValue:user forKey:@"username"];
        [request setCompletionBlock:^{
            NSDictionary *reply = [[request responseString] JSONValue];
            
            sqlite3 *database;
            int rslt = sqlite3_open([databasePath UTF8String], &database);
            if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
                NSArray *datas = [reply valueForKey:@"DATA"];
                for(NSDictionary *dict in datas){
                    if(rslt == SQLITE_OK){
                        // kTableFieldID, kTableFieldName, kTableFieldDesc, kTableFieldPrice, kTableFieldThumbnail, kTableFieldAllow, kTableFieldUser, kTableFieldType
                        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%d')", kTableNameStickerGroup, [dict valueForKey:@"package_id"], [[dict valueForKey:@"package_name"] stringByReplacingOccurrencesOfString:@"'" withString:@""], [[dict valueForKey:@"package_desc"] stringByReplacingOccurrencesOfString:@"'" withString:@""], [dict valueForKey:@"package_price"], [dict valueForKey:@"package_thumbnail"], [dict valueForKey:@"allow_use"], user, type];
                        
                        char *err = nil;
                        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
                        }
                        
                        NSLog(@"Error:%s", err);
                    }
                }
            }
            
            sqlite3_close(database);
           
            result = [self databaseFetchStickerGroupWithType:type forUser:user];
            [observer didFinishFetch:[NSDictionary dictionaryWithObjectsAndKeys:result, @"result", [NSNumber numberWithInt:type], @"type", nil]];

        }];
        [request startAsynchronous];
    }
}

-(void)fetchStickerWithType:(StickerType)type groupID:(NSInteger)group forUser:(NSString *)user observer:(id<SMPersistentObjectObserver>)observer{
    __block NSArray *result = [self databaseFetchStickerWithType:type groupID:group forUser:user];

    if(result.count > 0){
        [observer didFinishFetch:[NSDictionary dictionaryWithObjectsAndKeys:result, @"result", [NSNumber numberWithInt:type], @"type", [NSNumber numberWithInt:(int)group], @"group", nil]];
    }else{
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLStickerItems]];
        [request setPostValue:[NSNumber numberWithInt:(int)group] forKey:@"package_id"];
        [request setPostValue:user forKey:@"username"];
        [request setCompletionBlock:^{
            NSDictionary *reply = [[request responseString] JSONValue];
            
            sqlite3 *database;
            int rslt = sqlite3_open([databasePath UTF8String], &database);

            if([[reply valueForKey:@"STATUS"] isEqualToString:@"SUCCESS"]){
                NSArray *datas = [reply valueForKey:@"STICKERS"];
                for(NSDictionary *dict in datas){
                    if(rslt == SQLITE_OK){
                        //kTableFieldID, kTableFieldGroup, kTableFieldThumbnail, kTableFieldUser, kTableFieldType
                        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES ('%@', '%d', '%@', '%@', '%d')", kTableNameStickerItems, [dict valueForKey:@"sticker_id"], (int)group, [dict valueForKey:@"sticker_url"], user, type];
                        
                        char *err = nil;
                        
                        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
                        }
                    }
                }
            }
            
            sqlite3_close(database);
            
            result = [self databaseFetchStickerWithType:type groupID:group forUser:user];
            [observer didFinishFetch:[NSDictionary dictionaryWithObjectsAndKeys:result, @"result", [NSNumber numberWithInt:type], @"type", [NSNumber numberWithInt:(int)group], @"group", nil]];
            
        }];
        [request startAsynchronous];
    }
    
    ASIFormDataRequest *lapor = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:kURLStickerDownload]];
    [lapor setPostValue:user forKey:@"username"];
    [lapor setPostValue:[NSNumber numberWithInt:(int)group] forKey:@"package_id"];
    [queue addOperation:lapor];
    [lapor setCompletionBlock:^{
        //NSLog(@"result %@", [request responseString]);
    }];
}

-(void)collectAdressBookDataForUser:(NSString *)user{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                             (unsigned long)NULL), ^(void) {
        
        ABAddressBookRef addressBook = ABAddressBookCreate();
        
        __block BOOL accessGranted = NO;
        
        if (ABAddressBookRequestAccessWithCompletion != NULL) { // we're on iOS 6
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                accessGranted = granted;
                dispatch_semaphore_signal(sema);
            });
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_release(sema);
        }
        else { // we're on iOS 5 or older
            accessGranted = YES;
        }
        
        
        if (accessGranted) {
            if (!addressBook) {
                NSLog(@"opening address book");
            }
            
            CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
            CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
            
            sqlite3 *database;
            int rslt = sqlite3_open([databasePath UTF8String], &database);
            
            if(rslt == SQLITE_OK){
                NSString *sql = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE 1", kTableNameContacts];
                
                char *err = nil;
                if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
                }
            }
            
            for (int i=0;i < nPeople;i++) {
                ABRecordRef ref = CFArrayGetValueAtIndex(allPeople,i);
                
                //For username and surname
                ABMultiValueRef phones =(NSString*)ABRecordCopyValue(ref, kABPersonPhoneProperty);
                NSString *firstName =(NSString*)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
                NSString *lastName =(NSString*)ABRecordCopyValue(ref, kABPersonLastNameProperty);
                NSString *namaLengkap = nil;
                
                if(firstName){
                    namaLengkap = [NSString stringWithString:firstName];
                    [firstName release];
                }
                if(lastName){
                    namaLengkap = [namaLengkap stringByAppendingFormat:@" %@", lastName];
                    [lastName release];
                }
                
                //For Email ids
                NSString *email = nil;
                ABMutableMultiValueRef eMail  = ABRecordCopyValue(ref, kABPersonEmailProperty);
                if(ABMultiValueGetCount(eMail) > 0) {
                    email = (NSString *)ABMultiValueCopyValueAtIndex(eMail, ABMultiValueGetCount(eMail)-1);
                }
                
                if(eMail != NULL)
                    CFRelease(eMail);
                
                //For Phone number
                NSString* mobileLabel = nil;
                NSString *phoneNumber = nil;
                for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                    mobileLabel = (NSString*)ABMultiValueCopyLabelAtIndex(phones, i);
                    if([mobileLabel isEqualToString:(NSString *)kABPersonPhoneMobileLabel])
                    {
                        phoneNumber = (NSString*)ABMultiValueCopyValueAtIndex(phones, i);
                    }
                    else if ([mobileLabel isEqualToString:(NSString*)kABPersonPhoneIPhoneLabel])
                    {
                        phoneNumber = (NSString*)ABMultiValueCopyValueAtIndex(phones, i);
                        break ;
                    }
                }
            
                if(phones != NULL)
                    CFRelease(phones);
                
                if(rslt == SQLITE_OK && (phoneNumber.length > 0 || email.length > 0) && namaLengkap.length > 3){
                    // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES ('%@', '%@', '%@')", kTableNameContacts, namaLengkap, phoneNumber?phoneNumber:@"", email?email:@""];
                    //NSLog(@"nanananana %@", sql);
                    char *err = nil;
                    if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
                        //NSLog(@"tah error %s", err);
                    }
                }
                
                if(email != NULL)
                    [email release];
                
                [mobileLabel release];
                [phoneNumber release];
            }
            
            sqlite3_close(database);
            
            CFRelease(allPeople);
        }
    });
}

-(NSArray *)getRandomContact:(NSInteger)count{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY RANDOM() LIMIT %d", kTableNameContacts, (int)count];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                //char *name = (char *)sqlite3_column_text(statement, 0);
                char *phone = (char *)sqlite3_column_text(statement, 1);
                char *mail = (char *)sqlite3_column_text(statement, 2);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                //[row setValue:[NSString stringWithUTF8String:name] forKey:kTableFieldName];
                [row setValue:[NSString stringWithUTF8String:phone] forKey:kTableFieldPhone];
                [row setValue:[NSString stringWithUTF8String:mail] forKey:kTableFieldEmail];
                
                [data addObject:row];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return data;
}

-(NSArray *)contactArrayWithEmail{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE LENGTH(%@)>3", kTableNameContacts, kTableFieldEmail];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                char *name = (char *)sqlite3_column_text(statement, 0);
                //char *phone = (char *)sqlite3_column_text(statement, 1);
                char *mail = (char *)sqlite3_column_text(statement, 2);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                NSString *nameStr = [NSString stringWithUTF8String:name];
                NSString *mailStr = [NSString stringWithUTF8String:mail];
                [row setValue:nameStr forKey:kTableFieldName];
                [row setValue:mailStr forKey:kTableFieldEmail];
                //[row setValue:[NSString stringWithUTF8String:mail] forKey:kTableFieldEmail];
                if(nameStr.length > 0 && mailStr.length > 0)
                    [data addObject:row];            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return [data sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSString *str1 = [obj1 valueForKey:kTableFieldName];
        NSString *str2 = [obj2 valueForKey:kTableFieldName];
        return [str1 compare:str2];
    }];
}

-(NSArray *)contactArrayWithPhone{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE LENGTH(%@)>3", kTableNameContacts, kTableFieldPhone];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                char *name = (char *)sqlite3_column_text(statement, 0);
                char *phone = (char *)sqlite3_column_text(statement, 1);
                //char *mail = (char *)sqlite3_column_text(statement, 2);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                NSString *nameStr = [NSString stringWithUTF8String:name];
                NSString *phoneStr = [NSString stringWithUTF8String:phone];
                [row setValue:nameStr forKey:kTableFieldName];
                [row setValue:phoneStr forKey:kTableFieldPhone];
                //[row setValue:[NSString stringWithUTF8String:mail] forKey:kTableFieldEmail];
                if(nameStr.length > 0 && phoneStr.length > 0)
                    [data addObject:row];

            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return [data sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        NSString *str1 = [obj1 valueForKey:kTableFieldName];
        NSString *str2 = [obj2 valueForKey:kTableFieldName];
        return [str1 compare:str2];
    }];
}

-(void)addNewVisitor:(NSString *)username{
    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    if(rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES ('%@', '%lf', '0');", kTableNameVisitor, username, [[NSDate date] timeIntervalSince1970]];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
        
        NSLog(@"add new visitor %s", err);
    }
    sqlite3_close(database);
}

-(NSMutableArray *)getVisitors:(NSInteger)num{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC LIMIT %d;", kTableNameVisitor, kTableFieldDate, (int)num];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                char *name = (char *)sqlite3_column_text(statement, 0);
                double time = sqlite3_column_double(statement, 1);
                int viewed = sqlite3_column_int(statement, 2);
                //char *mail = (char *)sqlite3_column_text(statement, 2);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                NSString *nameStr = [NSString stringWithUTF8String:name];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
                [row setValue:nameStr forKey:kTableFieldName];
                [row setValue:date forKey:kTableFieldDate];
                [row setValue:[NSNumber numberWithInt:viewed] forKey:kTableFieldViewed];
                [data addObject:row];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    NSLog(@"data visitor %@", data);
    return data;
}

-(void)clearUnviewedVisitor{
    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    if(rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@=1 WHERE 1", kTableNameVisitor, kTableFieldViewed];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
    }
    sqlite3_close(database);
}

-(NSInteger)getUnviewedVisitorNum{
    int viewed = 0;
    
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@=0;", kTableNameVisitor, kTableFieldViewed];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                
                viewed = sqlite3_column_int(statement, 0);
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return viewed;
}

-(void)addFriendsUpdate:(NSString *)name message:(NSString *)msg{
    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    if(rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES ('%@', '%@', '%lf', '0');", kTableNameFriendsUpdate, name, msg, [[NSDate date] timeIntervalSince1970]];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
        
        NSLog(@"add new visitor %s", err);
    }
    sqlite3_close(database);
}

-(NSMutableArray *)getFriendsUpdate:(NSInteger)num{
    NSMutableArray *data = [NSMutableArray array];
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY %@ DESC LIMIT %d;", kTableNameFriendsUpdate, kTableFieldDate, (int)num];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                char *name = (char *)sqlite3_column_text(statement, 0);
                char *desc = (char *)sqlite3_column_text(statement, 1);
                double time = sqlite3_column_double(statement, 2);
                int viewed = sqlite3_column_int(statement, 3);
                //char *mail = (char *)sqlite3_column_text(statement, 2);
                
                NSMutableDictionary *row = [NSMutableDictionary dictionary];
                NSString *nameStr = [NSString stringWithUTF8String:name];
                NSString *descStr = [NSString stringWithUTF8String:desc];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
                [row setValue:nameStr forKey:kTableFieldName];
                [row setValue:descStr forKey:kTableFieldDesc];
                [row setValue:date forKey:kTableFieldDate];
                [row setValue:[NSNumber numberWithInt:viewed] forKey:kTableFieldViewed];
                [data addObject:row];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    NSLog(@"data visitor %@", data);
    return data;
}

-(void)clearUnviewedFriendUpdate{
    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    if(rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@=1 WHERE 1", kTableNameFriendsUpdate, kTableFieldViewed];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
    }
    sqlite3_close(database);
}

-(NSInteger)getUnviewedFriendUpdate{
    int viewed = 0;
    
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@=0;", kTableNameFriendsUpdate, kTableFieldViewed];
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                // kTableFieldName, kTableFieldPhone, kTableFieldEmail
                
                viewed = sqlite3_column_int(statement, 0);
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return viewed;
}

-(NSArray *)emoticonsGrouped:(BOOL)grouped{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"smilesdata" ofType:@"sqlite"];
    
    NSMutableArray *data = [NSMutableArray array];
    
    sqlite3 *database;
    int result = sqlite3_open([path UTF8String], &database);
    if(result == SQLITE_OK){
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ GROUP BY %@", kTableNameEmoticon, kTableFieldImage];
        
        if(!grouped)
            query = [NSString stringWithFormat:@"SELECT * FROM %@ ORDER BY LENGTH(plain) DESC", kTableNameEmoticon];
        
        sqlite3_stmt *statement;
        if(sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK){
            while(sqlite3_step(statement) == SQLITE_ROW){
                char *plain = (char *)sqlite3_column_text(statement, 0);
                char *image = (char *)sqlite3_column_text(statement, 1);
                char *unicode = (char *)sqlite3_column_text(statement, 2);
                
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSString stringWithUTF8String:plain], kTableFieldPlain,
                                      [NSString stringWithUTF8String:image], kTableFieldImage,
                                      [NSString stringWithUTF8String:unicode], kTableFieldUnicode,
                                      nil];
                [data addObject:dict];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return data;
}

#pragma mark - Resend Message

- (NSMutableArray *)fetchResendMessage:(NSString *)sender receiver:(NSString *)receiver {

    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);
    
    if (result == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE sender='%@' AND receiver='%@'", kTableNameResendMessage, sender, receiver];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt:sqlite3_column_int(statement, 0)], @"id",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)], @"message",
                                             [NSNumber numberWithBool:sqlite3_column_int(statement, 2)], @"outgoing",
                                             [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 3)], @"time",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)], @"text",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)], @"sender",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)], @"receiver", nil];
                [array addObject:dict];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return array;
}

- (NSMutableDictionary *)fetchResendMessageById:(int)nID {
    
    sqlite3 *database;
    NSMutableDictionary *resendMsgDict = NULL;
    
    int result = sqlite3_open([databasePath UTF8String], &database);
    
    if (result == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE id='%d'", kTableNameResendMessage, nID];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt:sqlite3_column_int(statement, 0)], @"id",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)], @"message",
                                             [NSNumber numberWithBool:sqlite3_column_int(statement, 2)], @"outgoing",
                                             [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(statement, 3)], @"time",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 4)], @"text",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 5)], @"sender",
                                             [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 6)], @"receiver", nil];
                resendMsgDict = dict;
                break;
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return resendMsgDict;
}

- (int)addResendMessage:(NSMutableDictionary *)messageDict {

    sqlite3 *database;
    int lastRowId = -1;
    
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    NSLog(@"%@", databasePath);
    
    if (rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (null, '%@', '%d', '%f', '%@', '%@', '%@');", kTableNameResendMessage, messageDict[@"message"], [messageDict[@"outgoing"] boolValue], [messageDict[@"time"] timeIntervalSince1970], messageDict[@"text"], messageDict[@"sender"], messageDict[@"receiver"]];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
            lastRowId = (int)sqlite3_last_insert_rowid(database);
        }
        
        NSLog(@"add new resend message %s", err);
    }
    sqlite3_close(database);
    
    return lastRowId;
}

- (void)deleteResendMessage:(int)resendMessageId {

    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    if (rslt == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE id='%d'", kTableNameResendMessage, resendMessageId];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
            NSLog(@"delete resend message %s", err);
        }
    }
    sqlite3_close(database);
}

#pragma mark - Only Invite Admin

- (NSDictionary *)fetchOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare {

    NSDictionary *dict = NULL;
    
    sqlite3 *database;
    int result = sqlite3_open([databasePath UTF8String], &database);

    if (result == SQLITE_OK) {
        NSString *query = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE groupname='%@' AND groupbare='%@'", kTableNameOnlyInviteAdmin, groupName, groupBare];
        sqlite3_stmt *statement;
        
        if (sqlite3_prepare_v2(database, [query UTF8String], -1, &statement, nil) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt:sqlite3_column_int(statement, 0)], @"id",
                        [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 1)], @"groupname",
                        [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 2)], @"groupbare",
                        [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, 3)], @"adminusername",
                        [NSNumber numberWithBool:sqlite3_column_int(statement, 4)], @"onlyinviteadmin", nil];
            }
        }
        sqlite3_finalize(statement);
    }
    sqlite3_close(database);
    
    return dict;
}

- (void)addOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare adminUser:(NSString *)adminUserName onlyInviteAdmin:(BOOL)onlyInviteAdmin {

    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    if (rslt == SQLITE_OK){
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ VALUES (null, '%@', '%@', '%@', '%d');", kTableNameOnlyInviteAdmin, groupName, groupBare, adminUserName, onlyInviteAdmin];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
    }
    sqlite3_close(database);
}

- (void)deleteOnlyInviteAdmin:(NSString *)groupName bare:(NSString *)groupBare {
    
    sqlite3 *database;
    int rslt = sqlite3_open([databasePath UTF8String], &database);
    
    if (rslt == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE groupname='%@' AND groupbare='%@'", kTableNameOnlyInviteAdmin, groupName, groupBare];
        
        char *err = nil;
        if(sqlite3_exec(database, [sql UTF8String], NULL, NULL, &err)== SQLITE_OK){
        }
    }
    sqlite3_close(database);
}

@end
