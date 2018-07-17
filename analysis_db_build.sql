CREATE DATABASE [ae_analysis];
GO
USE [ae_analysis];
GO
DROP TABLE IF EXISTS dbo.summary;
GO
CREATE TABLE dbo.summary (
    Test varchar(10) not null
  , Cycle tinyint not null
  , WorkloadID uniqueidentifier not null
  , Hostname sysname not null
  , [Workload] varchar(6) not null
  , TimeStart datetime
  , TimeEnd datetime
  , ElapsedTime_in_ms bigint
  , CountTasksRequested int
  , WorkerThreads tinyint
);
GO
DROP TABLE IF EXISTS dbo.detail;
CREATE TABLE dbo.detail (
    WorkloadID uniqueidentifier not null
  , [Workload] varchar(6) not null
  , Thread int not null
  , ProcessID int not null
  , DatetimeStart datetime not null
  , Duration decimal(25,5) not null
  , ErrorCount int not null
);
GO