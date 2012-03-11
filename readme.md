# SQLiteManager

SQLiteManager is a manager of SQL statements for iOS projects in objective-c.
SQLiteManager follows the  ***Singleton ****** design pattern to simplify its use throughout the project.
In an MVC design pattern, SQLiteManager can be regarded as the parent class of the  ***Model*** layer.

# Install #

Drag and drop files ***SQLiteManager.h*** and ***SQLiteManager.m*** in your project in Xcode.

Add to your frameworks list ***libsqlite3.dylib*** to your project.

Add your database to your project eg  ***datables.sqlite*** .
To create a sqlite database, you can use the [sqlite manager firefox addon](https://addons.mozilla.org/fr/firefox/addon/sqlite-manager/).

Edit ***SQLiteManager.h*** and enter the name of your database to the constant ***databaseName*** with its extension.

When you want to use SQLiteManager, `#import "SQLiteManager.h"` in your code file:

	

You can now access method SQLiteManager this way `[SQLiteManager singleton]`:
	
# How to use #

***Note :*** All optional parameters must be set to ***nil*** if they are not used.

## CREATE

	-(BOOL)save:(NSMutableDictionary *)data into:(NSString *)table;

Insert a new row in a table.

 * @ param1: the fields and data to be saved
 * @ param2: name of the table
 * @ return: `YES` if successful, otherwise `NO`


#### Example

	NSMutableDictionary *dataSave = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"value1",@"field1",
                              @"value2",@"field2",
                              nil];               
	[[SQLiteManager singleton] save:dataSave into:@"tableName"];

## READ

### All

	-(NSArray *)findAllFrom:(NSString *)table;

Reads all rows from a table.

 * @ param1: table name
 * @ return: rows of table


#### Example

	NSArray *result = [[SQLiteManager singleton] findAllFrom:@"TableName"];

### Custom 1

	-(NSArray *)find:(NSString *)field from:(NSString *)table where:(NSString *)condition;

Read some field of a table with condition.

 * @ param1: (optional) fields required
 * @ param2: name of the table
 * @ param3: (optional) The conditions
 * @ return: rows of table


#### Example

	NSArray *result = [[SQLiteManager singleton] find:@"field1,field2" from:@"tableName" where:@"field2=value"];


### Custom 2
	
	-(NSArray *)find:(NSString *)field from:(NSString *)table where:(NSString *)condition order:(NSString *)order limit:(NSString *)limit;

Read some field of a table with criteria, sorting and limit.

 * @ param1: (optional) fields required
 * @ param2: name of the table
 * @ param3: (optional) The conditions
 * @ param4: (optional) sort order
 * @ param5: (optional) number limit
 * @ return: rows of table


#### Example

	NSArray *result = [[SQLiteManager singleton] find:@"field1,field2" from:@"tableName" where:@"field2=value" order:@"field3 ASC" limit:@"5"];

## UPDATE

Update is used the same method of Create.
Except that in the data table must be specified Backup Id.


#### Example

	NSMutableDictionary *dataSave = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              @"4",@"id",						
                              @"value1",@"field1",
                              @"value2",@"field2",
                              nil];

## DELETE

	-(BOOL)deleteRowWithId:(int)idRow from:(NSString *)table;

Deletes a row from a table.

 * @ param1: id of row
 * @ param2: name of the table
 * @ return: `YES` if successful, otherwise `NO`

## Specific SQL query

	-(id)executeSql:(NSString *)sql;

Executes a sql query.

 * @ param1: sql query
 * @ return: `NSArray` if it's an read query, else `YES` if successful, otherwise `NO`.


#### Example 1

	NSString *sql = @"SELECT * FROM tableName WHERE id=3 OR id=7";
    NSArray *result =[[SQLiteManager singleton] executeSql:sql];

#### Example 2

	NSString *sql = @"UPDATE tableName SET field1 = 'value1' WHERE field2 != 'value2' OR field3 = 'value3'";
    [[SQLiteManager singleton] executeSql:sql];

# Credits #

### Author

[Anthony Ly](mailto:anthonyly.com@gmail.com)