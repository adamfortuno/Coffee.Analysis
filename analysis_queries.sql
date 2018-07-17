/******************************************************************************
	.Synopsis
	Get the Transactions Per Minute (TPM)

	.Description
	Gets the transactions per minute (TPM) for a given
	result set.
******************************************************************************/
USE [ae_analysis];
GO
;WITH transactions_per_second AS (
	SELECT WorkloadID
		 , Workload
		 , DATEPART(hour, DatetimeStart) AS [hour]
		 , DATEPART(MINUTE, DatetimeStart) AS [minute]
         , DATEPART(second, DatetimeStart) AS [second]
		 , COUNT(*) AS [volume]
	  FROM dbo.detail
	 GROUP BY WorkloadID
		 , Workload
		 , DATEPART(hour, DatetimeStart)
		 , DATEPART(MINUTE, DatetimeStart)
		 , DATEPART(second, DatetimeStart)
)
SELECT RANK() OVER (partition by smry.Test ORDER BY tpm.[hour], tpm.[minute], tpm.[second]) AS [segment]
     , smry.Test
     , tpm.[workload]
     , tpm.volume
  FROM transactions_per_minute tpm INNER JOIN dbo.summary smry
        ON tpm.WorkloadID = smry.WorkloadID
 ORDER BY [segment]
GO

/******************************************************************************
	.Synopsis
	Get the Transactions Per Minute (TPM)

	.Description
	Gets the transactions per minute (TPM) for a given
	result set.
******************************************************************************/
USE [ae_analysis];
GO
--- Generates the number of transactions per minute 
--- by test and workload
;WITH transactions_per_minute AS (
	SELECT DENSE_RANK() OVER (partition by smry.Test ORDER BY DATEPART(hour, detl.DatetimeStart), DATEPART(MINUTE, detl.DatetimeStart)) AS segment
	     , smry.Test
		 , smry.Workload
		 , COUNT(*) AS [volume]
	  FROM dbo.summary smry INNER JOIN dbo.detail detl
	        ON smry.WorkloadID = detl.WorkloadID
	 GROUP BY smry.Test
		 , smry.Workload
		 , DATEPART(hour, detl.DatetimeStart)
		 , DATEPART(MINUTE, detl.DatetimeStart)
)
--- Retrieve a list of segments
, segment_list AS (
	SELECT segment, [workload] FROM transactions_per_minute GROUP BY segment, workload
)
--- Retrieves all data for no-encryption (baseline)
, segments_base AS (
	SELECT * FROM transactions_per_minute WHERE Test = 'base'
)
--- Retrieves all data for Always Encrypted w/WCS Integration
, segments_wcs AS (
	SELECT * FROM transactions_per_minute WHERE Test = 'ae.wcs'
)
--- Retrieves all data for Always Encrypted w/HSM Integration
, segments_hsm AS (
	SELECT * FROM transactions_per_minute WHERE Test = 'ae.hsm'
)
--- Retrieves Always Encrypted WCS and HSM Against Baseline by Segment
, comparison (segment, [workload], wcs_perf, hsm_perf) AS (
	SELECT sl.segment
		 , sw.[Workload]
		 , CAST(sw.volume AS numeric(10,5)) / CAST(sb.volume AS numeric (10,5)) * 100
		 , CAST(sh.volume AS numeric(10,5)) / CAST(sb.volume AS numeric (10,5)) * 100
	  FROM segment_list sl LEFT JOIN segments_base sb
			ON sl.segment = sb.segment AND sl.Workload = sb.Workload
		   LEFT JOIN segments_wcs sw 
			ON sl.segment = sw.segment AND sl.Workload = sw.Workload
		   LEFT JOIN segments_hsm sh 
			ON sl.segment = sh.segment AND sl.Workload = sh.Workload
	 WHERE sb.volume IS NOT NULL
)
--- Provides Average TPM by Test and Workload
SELECT [workload]
     , avg(wcs_perf) AS [wcs]
     , avg(hsm_perf) AS [hsm]
  FROM comparison
 WHERE [workload] IS NOT NULL
 GROUP BY [workload]
GO

/******************************************************************************
	.Synopsis
	Aggregates Transaction Counts by Frequency Distribution

	.Description
	Creates 5-minute buckets and calculates transaction
	counts by bucket, test, and workload.
	
******************************************************************************/
;WITH transactions_per_minute AS (
	SELECT WorkloadID
         , Workload
         , DATEPART(hour, DatetimeStart) AS [hour]
         , DATEPART(MINUTE, DatetimeStart) AS [minute]
         , COUNT(*) AS [volume]
      FROM dbo.detail
     GROUP BY WorkloadID
         , Workload
         , DATEPART(hour, DatetimeStart)
         , DATEPART(MINUTE, DatetimeStart)
)
--- Change Minutes to Generic Segments
, segment_by_minute AS (
	SELECT s.Test
         , f.workload
         , RANK() OVER (partition by s.Test ORDER BY f.minute, f.volume) AS executing_minute
         , f.volume
      FROM transactions_per_minute f INNER JOIN dbo.summary s
            ON f.WorkloadID = s.WorkloadID
)
--- Retrieve segment ranges
, ranges AS (
	SELECT 1 AS [start], 5 AS [end]
	 UNION ALL
	SELECT [end]
		 , [end] + 5 -- recursive member
	  FROM ranges
	 WHERE [start] < 900 -- terminator
)
SELECT rng.[start]
     , rng.[end]
     , bar.Test
     , bar.workload
     , SUM(bar.volume)
  FROM ranges rng INNER JOIN segment_by_minute bar
        ON bar.executing_minute BETWEEN rng.[start] AND rng.[end]
 GROUP BY rng.[start]
     , rng.[end]
     , bar.Test
     , bar.workload
OPTION (MAXRECURSION 200)
GO


