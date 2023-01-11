-- Connect to SQL Server
-- THis will restore the AdventureWorksDW2017 database in a standard way. There are technically more options. See RESTORE DATBASE docuementation in microsoft for more info.
USE [master]
RESTORE DATABASE [AdventureWorksDW2017] FROM  DISK = N'C:\SQL Server\Backups\AdventureWorksDW2017.bak' WITH  FILE = 1
,  MOVE N'AdventureWorksDW2017' TO N'C:\SQL Server\Data\AdventureWorksDW2017.mdf'
,  MOVE N'AdventureWorksDW2017_log' TO N'C:\SQL Server\Logs\AdventureWorksDW2017_log.ldf'
,  NOUNLOAD
,  STATS = 5
