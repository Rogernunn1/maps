//
//  Sqlite.m
//

#import "Sqlite.h"

/* ============================================================================
 */
@interface Sqlite (PRIVATE)
- (BOOL)executeStatament:(sqlite3_stmt *)stmt;
- (BOOL)prepareSql:(NSString *)sql inStatament:(sqlite3_stmt **)stmt;
- (void) bindObject:(id)obj toColumn:(int)idx inStatament:(sqlite3_stmt *)stmt;

- (BOOL)hasData:(sqlite3_stmt *)stmt;
- (id)columnData:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index;
- (NSString *)columnName:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index;
@end

@implementation Sqlite

@synthesize busyRetryTimeout;
@synthesize filePath;

+ (NSString *)createUuid {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	CFRelease(uuidRef);
	return((NSString *) CFBridgingRelease(uuidStringRef) );
}

+ (NSString *)version {
	return [NSString stringWithFormat:@"%s", sqlite3_libversion()];
}

- (id)init {
	if ((self = [super init])) {
		busyRetryTimeout = 1;
		filePath = nil;
		_db = nil;
	}

	return self;
}

- (id)initWithFile:(NSString *)dbFilePath {
	if (self = [super init]) {
		[self open:dbFilePath];
	}
	
	return self;
}



- (BOOL)open:(NSString *)path {
	[self close];
	
	if (sqlite3_open([path fileSystemRepresentation], &_db) != SQLITE_OK) {
		NSLog(@"SQLite Opening Error: %s", sqlite3_errmsg(_db));
//        [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

		return NO;
	}

	filePath = path ;
	return YES;
}

- (void)close {
	if (_db == nil) return;

	int numOfRetries = 0;
	int rc;
	
	do {
		rc = sqlite3_close(_db);
		if (rc == SQLITE_OK)
			break;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy, unable to close: %@", filePath);
				break;
			}
		} else {
//            [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

			NSLog(@"SQLite %@ Closing Error: %s", filePath, sqlite3_errmsg(_db));

			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	filePath = nil;
	_db = nil;
}

- (NSInteger)errorCode {
	return sqlite3_errcode(_db);
}

- (NSString *)errorMessage {
//    [[[UIAlertView alloc] initWithTitle:@"Error!" message:[NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

	return [NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)];
    
}

-(NSMutableString*) sqlite3StmtToString:(sqlite3_stmt*) statement
{
    NSMutableString *s = [NSMutableString new];
    [s appendString:@"{\"statement\":["];
    for (int c = 0; c < sqlite3_column_count(statement); c++){
        [s appendFormat:@"{\"column\":\"%@\",\"value\":\"%@\"}",[NSString stringWithUTF8String:(char*)sqlite3_column_name(statement, c)],[NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, c)]];
        if (c < sqlite3_column_count(statement) - 1)
            [s appendString:@","];
    }
    [s appendString:@"]}"];
    return s;
}

- (NSArray *)executeQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);

	NSMutableArray *argsArray = [[NSMutableArray alloc] init];
	NSUInteger i;
	for (i = 0; i < [sql length]; ++i) {
		if ([sql characterAtIndex:i] == '?')
			[argsArray addObject:va_arg(args, id)];
	}
	
	va_end(args);
	
	NSArray *result = [self executeQuery:sql arguments:argsArray];

	return result;
}

- (NSArray *)executeQuery:(NSString *)sql arguments:(NSArray *)args {
	sqlite3_stmt *sqlStmt;
	
	if (![self prepareSql:sql inStatament:(&sqlStmt)])
		return nil;

	int i = 0;
	int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
	while (i++ < queryParamCount)
		[self bindObject:[args objectAtIndex:(i - 1)] toColumn:i inStatament:sqlStmt];

	NSMutableArray *arrayList = [[NSMutableArray alloc] init];
	int columnCount = sqlite3_column_count(sqlStmt);
	while ([self hasData:sqlStmt]) {
		NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
		for (i = 0; i < columnCount; ++i) {
			id columnName = [self columnName:sqlStmt columnIndex:i];
			id columnData = [self columnData:sqlStmt columnIndex:i];
			[dictionary setObject:columnData forKey:columnName];
		}
		[arrayList addObject:dictionary];
	}

	sqlite3_finalize(sqlStmt);

	return arrayList;
}

- (BOOL)executeNonQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);

	NSMutableArray *argsArray = [[NSMutableArray alloc] init];

    // To remedy this as a temporary hack I am removing the follwing check
    // This means that we will not be ablt to use "?" and associated variable 
    // in a query. Currently we are not using any such query so we are safe
    // and we will not be breaking any functionality.

//    NSUInteger i;
//	for (i = 0; i < [sql length]; ++i) {
//		if ([sql characterAtIndex:i] == '?')
//			[argsArray addObject:va_arg(args, id)];
//	}
	
	va_end(args);
	
	BOOL success = [self executeNonQuery:sql arguments:argsArray];

	return success;
}

- (BOOL)executeNonQuery:(NSString *)sql arguments:(NSArray *)args {
	sqlite3_stmt *sqlStmt;

	if (![self prepareSql:sql inStatament:(&sqlStmt)])
		return NO;

	int i = 0;
	int queryParamCount = sqlite3_bind_parameter_count(sqlStmt);
	while (i++ < queryParamCount)
		[self bindObject:[args objectAtIndex:(i - 1)] toColumn:i inStatament:sqlStmt];

	BOOL success = [self executeStatament:sqlStmt];

	sqlite3_finalize(sqlStmt);
	return success;	
}

- (BOOL)commit {
	return [self executeNonQuery:@"COMMIT TRANSACTION;"];
}

- (BOOL)rollback {
	return [self executeNonQuery:@"ROLLBACK TRANSACTION;"];
}

- (BOOL)beginTransaction {
	return [self executeNonQuery:@"BEGIN EXCLUSIVE TRANSACTION;"];
}

- (BOOL)beginDeferredTransaction {
	return [self executeNonQuery:@"BEGIN DEFERRED TRANSACTION;"];
}

/* ============================================================================
 *  PRIVATE Methods
 */

- (BOOL)prepareSql:(NSString *)sql inStatament:(sqlite3_stmt **)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, stmt, NULL);
		if (rc == SQLITE_OK)
			return YES;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
			NSLog(@"SQLite Prepare Failed: %s", sqlite3_errmsg(_db));
			NSLog(@" - Query: %@", sql);
//            [[[UIAlertView alloc] initWithTitle:@"Prepare Failed!" message:[NSString stringWithFormat:@"%s\n%@", sqlite3_errmsg(_db),sql] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (BOOL)executeStatament:(sqlite3_stmt *)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_step(stmt);
		if (rc == SQLITE_OK || rc == SQLITE_DONE)
			return YES;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
            
//            NSLog(@"%@",[self sqlite3StmtToString:stmt]);
//            [[[UIAlertView alloc] initWithTitle:@"Execute Failed!" message:[NSString stringWithFormat:@"%@", [self sqlite3StmtToString:stmt]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

			NSLog(@"SQLite Step Failed: %s", sqlite3_errmsg(_db));
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (void)bindObject:(id)obj toColumn:(int)idx inStatament:(sqlite3_stmt *)stmt {
	if (obj == nil || obj == [NSNull null]) {
		sqlite3_bind_null(stmt, idx);
	} else if ([obj isKindOfClass:[NSData class]]) {
		sqlite3_bind_blob(stmt, idx, [obj bytes], [obj length], SQLITE_STATIC);
	} else if ([obj isKindOfClass:[NSDate class]]) {
		sqlite3_bind_double(stmt, idx, [obj timeIntervalSince1970]);
	} else if ([obj isKindOfClass:[NSNumber class]]) {
		if (!strcmp([obj objCType], @encode(BOOL))) {
			sqlite3_bind_int(stmt, idx, [obj boolValue] ? 1 : 0);
		} else if (!strcmp([obj objCType], @encode(int))) {
			sqlite3_bind_int64(stmt, idx, [obj longValue]);
		} else if (!strcmp([obj objCType], @encode(long))) {
			sqlite3_bind_int64(stmt, idx, [obj longValue]);
		} else if (!strcmp([obj objCType], @encode(float))) {
			sqlite3_bind_double(stmt, idx, [obj floatValue]);
		} else if (!strcmp([obj objCType], @encode(double))) {
			sqlite3_bind_double(stmt, idx, [obj doubleValue]);
		} else {
			sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
		}
	} else {
		sqlite3_bind_text(stmt, idx, [[obj description] UTF8String], -1, SQLITE_STATIC);
	}
}

- (BOOL)hasData:(sqlite3_stmt *)stmt {
	int numOfRetries = 0;
	int rc;

	do {
		rc = sqlite3_step(stmt);
		if (rc == SQLITE_ROW)
			return YES;

		if (rc == SQLITE_DONE)
			break;

		if (rc == SQLITE_BUSY) {
			usleep(20);

			if (numOfRetries == busyRetryTimeout) {
				NSLog(@"SQLite Busy: %@", filePath);
				break;
			}
		} else {
//            [[[UIAlertView alloc] initWithTitle:@"Has Data!" message:[NSString stringWithFormat:@"%s", sqlite3_errmsg(_db)] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];

			NSLog(@"SQLite Prepare Failed: %s", sqlite3_errmsg(_db));
			break;
		}
	} while (numOfRetries++ > busyRetryTimeout);

	return NO;
}

- (id)columnData:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
	int columnType = sqlite3_column_type(stmt, index);

	if (columnType == SQLITE_NULL)
		return([NSNull null]);

	if (columnType == SQLITE_INTEGER)
		return [NSNumber numberWithInt:sqlite3_column_int(stmt, index)];

	if (columnType == SQLITE_FLOAT)
		return [NSNumber numberWithDouble:sqlite3_column_double(stmt, index)];

	if (columnType == SQLITE_TEXT) {
		const unsigned char *text = sqlite3_column_text(stmt, index);
		return [NSString stringWithUTF8String:(char *) text];
	}

	if (columnType == SQLITE_BLOB) {
		int nbytes = sqlite3_column_bytes(stmt, index);
		const char *bytes = sqlite3_column_blob(stmt, index);
		return [NSData dataWithBytes:bytes length:nbytes];
	}

	return nil;
}

- (NSString *)columnName:(sqlite3_stmt *)stmt columnIndex:(NSInteger)index {
	return [NSString stringWithUTF8String:sqlite3_column_name(stmt, index)];
}

@end

