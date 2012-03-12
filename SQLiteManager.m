//
//  SQLiteManager.m
//
//  Created by Anthony Ly on 11/03/12.
//  Copyright (c) 2012 AnthonyLy.com. All rights reserved.
//

#import "SQLiteManager.h"

@implementation SQLiteManager
@synthesize databasePath;
#pragma Singleton
static SQLiteManager * sharedSQLiteManager = nil;
+(SQLiteManager *)singleton{
    @synchronized([SQLiteManager class])
	{
		if (!sharedSQLiteManager){
            [[self alloc] init];
        }
		return sharedSQLiteManager;
	}
	return nil;
}
+(id)alloc{
	@synchronized([SQLiteManager class])
	{
		NSAssert(sharedSQLiteManager == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedSQLiteManager = [super alloc];
		return sharedSQLiteManager;
	}
	return nil;
}
- (id)autorelease {
    return self;
}
#pragma SQL : init
-(id)init {
	self = [super init];
	if (self != nil) {
        NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDir = [documentPaths objectAtIndex:0];
        self.databasePath = [documentsDir stringByAppendingPathComponent:databaseName];
		[self checkAndCreateDatabaseWithOverwrite:NO];
	}
	return self;
}
-(void) checkAndCreateDatabaseWithOverwrite:(BOOL)overwriteDB {
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:self.databasePath];
    if (success && !overwriteDB) {
        return;
    }
    NSString *databasePathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:databaseName];
	[fileManager copyItemAtPath:databasePathFromApp toPath:self.databasePath error:nil];
}
- (NSDictionary *)indexByColumnName:(sqlite3_stmt *)init_statement {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    int num_fields = sqlite3_column_count(init_statement);
    for(int index_value = 0; index_value < num_fields; index_value++) {
        const char* field_name = sqlite3_column_name(init_statement, index_value);
        if (!field_name){
            field_name="";
        }
        NSString *col_name = [NSString stringWithUTF8String:field_name];
        NSNumber *index_num = [NSNumber numberWithInt:index_value];
        [keys addObject:col_name];
        [values addObject:index_num];
    }
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [keys release];
    [values release];
    return dictionary;
}
#pragma SQL : FIND
-(NSArray *)_find:(NSString *)sql{
    sqlite3 *database;
	NSMutableArray *dataReturn = [[NSMutableArray alloc] init];
    if(sqlite3_open([self.databasePath UTF8String], &database) == SQLITE_OK) {
        const char *sqlStatement = (const char*)[sql UTF8String];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
            NSDictionary *dictionary = [self indexByColumnName:compiledStatement];
            while(sqlite3_step(compiledStatement) == SQLITE_ROW) {
				NSMutableDictionary * row = [[NSMutableDictionary alloc] init];
				for (NSString *field in dictionary) {
					char * str = (char *)sqlite3_column_text(compiledStatement, [[dictionary objectForKey:field] intValue]);
					if (!str){
						str=" ";
					}
					NSString * value = [NSString stringWithUTF8String:str];
					[row setObject:value forKey:field];
				}
				[dataReturn addObject:row];
				[row release];
            }
        }
		else {
            NSAssert1(0, @"Error sqlite3_prepare_v2 :. '%s'", sqlite3_errmsg(database));
        }
        sqlite3_finalize(compiledStatement);
	}
	else {
        NSAssert1(0, @"Error sqlite3_open :. '%s'", sqlite3_errmsg(database));
    }
    sqlite3_close(database);
	return dataReturn;
}
-(NSArray *)findAllFrom:(NSString *)table{
    NSString * sql = [NSString stringWithFormat:@"SELECT * FROM %@",table];
    return [self _find:sql];
}
-(NSArray *)find:(NSString *)field from:(NSString *)table where:(NSString *)condition{
    if (field == nil) {
        field = @"*";
    }
    if (condition == nil) {
        condition = @"1=1";
    }
    NSString *selectFromWhere = @"SELECT %@ FROM %@ WHERE %@";
    NSString * sql = [NSString stringWithFormat:selectFromWhere,field, table, condition];
    return [self _find:sql];
}
-(NSArray *)find:(NSString *)field from:(NSString *)table where:(NSString *)condition order:(NSString *)order limit:(NSString *)limit{
    NSString *selectFromWhere = @"SELECT %@ FROM %@ WHERE %@";
    NSString *selectFromWhereOrder = @"SELECT %@ FROM %@ WHERE %@ ORDER BY %@";
    NSString *selectFromWhereOrderLimit = @"SELECT %@ FROM %@ WHERE %@ ORDER BY %@ LIMIT %@";
    NSString * sql;
    if (field == nil) {
        field = @"*";
    }
    if (condition == nil) {
        condition = @"1=1";
    }
    if (order != nil && limit != nil) {
        sql = [NSString stringWithFormat:selectFromWhereOrderLimit,field, table, condition, order, limit];
    }else if(order == nil && limit != nil){
        sql = [NSString stringWithFormat:selectFromWhereOrder,field, table, condition, order];
    }else{
        sql = [NSString stringWithFormat:selectFromWhere,field, table, condition];
    }
    return [self _find:sql];
}
#pragma SQL : DELETE
-(BOOL)deleteRowWithId:(int)idRow from:(NSString *)table{
    sqlite3 *database;
    if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id = %d",table,idRow];
        const char *sqlStatement = (const char*)[sql UTF8String];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) != SQLITE_OK) {
            NSAssert1(0, @"Error sqlite3_prepare_v2 :. '%s'", sqlite3_errmsg(database));
            return NO;
        }
        if(SQLITE_DONE != sqlite3_step(compiledStatement)) {
            NSAssert1(0, @"Error sqlite3_step :. '%s'", sqlite3_errmsg(database));
            return NO;
        }else{
            sqlite3_finalize(compiledStatement);
            sqlite3_close(database);
            return YES;
        }
    }else{
        NSAssert1(0, @"Error sqlite3_open :. '%s'", sqlite3_errmsg(database));
        return NO;
    }
}
#pragma SQL : SAVE/UPDATE
-(BOOL)save:(NSMutableDictionary *)data into:(NSString *)table{
    sqlite3 *database;
    if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSArray *keys = [data allKeys];
		NSArray *values = [data allValues];
        NSString * sql;
        if ([data valueForKey:@"id"] != nil) {
            int idUpdate = [[data valueForKey:@"id"] intValue];
            NSString *updateSql = @"";
            for (NSString *key in keys) {
                if (![key isEqualToString:@"id"]) {
                    updateSql = [NSString stringWithFormat:@"%@,%@=?",updateSql,key];
                }
            }
            updateSql = [updateSql substringFromIndex:1];
            sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE id=%d",table, updateSql, idUpdate];
            [data removeObjectForKey:@"id"];
            values = [data allValues];
        }
        else{
            NSString *keysSql = @"";
            NSString *valuesSql = @"";
            for (NSString *key in keys) {
                keysSql = [NSString stringWithFormat:@"%@,%@",keysSql,key];
                valuesSql = [NSString stringWithFormat:@"%@,?",valuesSql];
            }
            keysSql = [keysSql substringFromIndex:1];
            valuesSql = [valuesSql substringFromIndex:1];
            sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",table, keysSql, valuesSql];
        }
        const char *sqlStatement = (const char*)[sql UTF8String];
        sqlite3_stmt *compiledStatement;
        if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
			int index = 1;
			for (NSString * value in values) {
				if( [[NSScanner scannerWithString:(NSString *)value] scanFloat:NULL] ){
					sqlite3_bind_int(compiledStatement, index, [(NSString*)value intValue]);
				}
                else {
					sqlite3_bind_text(compiledStatement, index, [(NSString *)value UTF8String], -1, SQLITE_TRANSIENT);
				}
				index++;
			}
            if(SQLITE_DONE != sqlite3_step(compiledStatement)) {
                NSAssert1(0, @"Error sqlite3_step :. '%s'", sqlite3_errmsg(database));
                return NO;
            }else{
                sqlite3_finalize(compiledStatement);
                sqlite3_close(database);
                return YES;
            }     
        }
        else {
            NSAssert1(0, @"Error sqlite3_prepare_v2 :. '%s'", sqlite3_errmsg(database));
            return NO;
        }
    }
    else {
        NSAssert1(0, @"Error sqlite3_open :. '%s'", sqlite3_errmsg(database));
        return NO;
    }
}
#pragma SQL : QUERY
-(id)executeSql:(NSString *)sql{
    NSNumber *returnYES = [NSNumber numberWithBool:YES];
    NSNumber *returnNO = [NSNumber numberWithBool:NO];
    NSCharacterSet *delimiterCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *firstWord = [[sql componentsSeparatedByCharactersInSet:delimiterCharacterSet] objectAtIndex:0];
    if ([firstWord isEqualToString:@"SELECT"]) {
        return [self _find:sql];
    }
    else{
        sqlite3 *database;
        if(sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
            const char *sqlStatement = (const char*)[sql UTF8String];
            sqlite3_stmt *compiledStatement;
            if(sqlite3_prepare_v2(database, sqlStatement, -1, &compiledStatement, NULL) == SQLITE_OK) {
            }
            if(SQLITE_DONE != sqlite3_step(compiledStatement)) {
                NSAssert1(0, @"Error sqlite3_open :. '%s'", sqlite3_errmsg(database));
                return returnNO;
            }else{
                sqlite3_finalize(compiledStatement);
                sqlite3_close(database);
                return returnYES;
            }
        }else{
            NSAssert1(0, @"Error sqlite3_open :. '%s'", sqlite3_errmsg(database));
            return returnNO;
        }
    }
}
@end
