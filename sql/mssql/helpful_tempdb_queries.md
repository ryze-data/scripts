# SQL Server TempDB 

```
USE tempdb;
/*
sp_helpdb tempdb;
*/
SELECT
	 Name AS DBFileName
	,file_id AS DBFileID
	,physical_name PathAndPhysicalName
	,(max_size * 8.0/1024) as MaxFileSizeMB
    ,(size * 8.0/1024) as FileSizeMB
    ,((size * 8.0/1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0/1024)) As FileFreeSpaceMB
	,cast((((size * 8.0/1024) - (FILEPROPERTY(name, 'SpaceUsed') * 8.0/1024))/(max_size * 8.0/1024))*100 as decimal(6,2)) as FreeSpacePercent
	,cast((( (FILEPROPERTY(name, 'SpaceUsed') * 8.0/1024))/(max_size * 8.0/1024))*100 as decimal(6,2)) as FullSpacePercent
    FROM sys.database_files;
GO
```

```
/*

TempDB overview

The TempDB database is one of the most important SQL Server system databases,

that is used to store temporary user objects, such as the temporary tables that

are defined by the user or returned from table-valued function execution,

temporary stored procedures, table variables or indexes.

In addition to the user objects, TempDB will be used to store internal

objects that are created by the SQL Server Database Engine during the

different internal operations, such as intermediate sorting, spooling,

aggregate or cursor operations.

The TempDB system database is used also to store the rows versions in order to support the features

that require tracking the changes that are performed on the table rows, such as the snapshot isolation

level of the transactions, Online Index rebuilds or the Multiple Active Result Sets feature.

TempDB database will be dropped and recreated again each time the SQL Server service is restarted, 

starting with a new clean copy of the database. Based on that fact, all the user and internal database objected that 

are stored on this database will be dropped automatically when the SQL Server service is restarted or 

when the session where these objects created is disconnected. Therefore the backup and restore operations 

are not available for the TempDB.

source: --https://www.sqlshack.com/how-to-detect-and-prevent-unexpected-growth-of-the-tempdb-database/

*/
```

# Read Error log
```
/* Read error log most recent 
DBCC showfilestats
GO
*/
EXEC xp_readerrorlog;
GO
```