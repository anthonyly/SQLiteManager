# SQLiteManager

SQLiteManager is a manager of SQL statements for iOS projects in objective-c.
SQLiteManager follows the  ***Singleton ****** design pattern to simplify its use throughout the project.
In an MVC design pattern, SQLiteManager can be regarded as the parent class of the  ***Model*** layer.

# Install #

Drag and drop files ***SQLiteManager.h*** and ***SQLiteManager.m*** in your project in Xcode.

Add to your frameworks list ***libsqlite3.dylib*** to your project.

Add your database to your project eg  ***datables.sqlite ***.
To create a sqlite database, you can use the [sqlite manager firefox addon](https://addons.mozilla.org/fr/firefox/addon/sqlite-manager/).

Edit ***SQLiteManager.h*** and enter the name of your database to the constant ***databaseName*** with its extension.

When you want to use SQLiteManager, import SQLiteManager.h dévut in your code file:

	#import "SQLiteManager.h"

You can now access method SQLiteManager this way:
	
	[SQLiteManager singleton];

# How to use #

***Note :*** All optional parameters must be set to ***nil*** if they are not used.

## CREATE

	-(BOOL)save:(NSMutableDictionary *)data into:(NSString *)table;

Insert a new row in a table.

@ param1: the fields and data to be saved

@ param2: name of the table

@ return: YES if successful, otherwise NO

Example

	NSMutableDictionary *dataSave = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"value1",@"field1",
                              @"value2",@"field2",
                              nil];               
	[[SQLiteManager singleton] save:dataSave into:@"tableName"];

## READ

	-(NSArray *)findAllFrom:(NSString *)table;

Reads all rows from a table.

@ param1: table name

@ return: rows of table

Example

	NSArray *result = [[SQLiteManager singleton] findAllFrom:@"TableName"];

## UPDATE

Update is used the same method of Create.
Except that in the data table must be specified Backup Id.

Example

	NSMutableDictionary *dataSave = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"4",@"id",						
                              @"value1",@"field1",
                              @"value2",@"field2",
                              nil];

## DELETE

	-(BOOL)deleteRowWithId:(int)idRow from:(NSString *)table;

Deletes a row from a table.

@ param1: id of row

@ param2: name of the table

@ return: YES if successful, otherwise NO
