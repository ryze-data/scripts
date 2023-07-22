

/* 
Script came from https://www.brentozar.com/blitz/tempdb-data-files/
This script example Re-sizes TempDB to 8 GB
*/
 
USE [master]; 
GO 
alter database tempdb modify file (name='tempdev', size = 8GB);
GO
 
/* Adding three additional files */
 
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'T:\MSSQL\DATA\tempdev2.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'T:\MSSQL\DATA\tempdev3.ndf' , SIZE = 8GB , FILEGROWTH = 0);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'T:\MSSQL\DATA\tempdev4.ndf' , SIZE = 8GB , FILEGROWTH = 0);
GO