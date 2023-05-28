USE [AVIA]
GO

/****** Object:  View [dbo].[v_sales_prediction]    Script Date: 28.05.2023 17:11:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO








CREATE VIEW [dbo].[v_sales_prediction]
WITH SCHEMABINDING
AS
--SELECT getdate() as [date]
SELECT
	mt.[SDAT_S]
	, mt.[SEG_CLASS_CODE]
	, t2.[SSCL1]
	, mt.[FLT_NUMSH]
	, mt.[DIRECTION]
	, mt.[DD]
	, t1.[AVG_SALES_FLY]
	, DATEDIFF(DAY, mt.[SDAT_S], mt.[DD]) [DD_NUM]
FROM
	(
	SELECT
		mt.[CAPTURE_DATE1] [SDAT_S]
		, mt.[SEG_CLASS_CODE]
		, t1.[FLT_NUMSH]
		, t1.[DIRECTION]
		, t1.[CAPTURE_DATE1] [DD]
	FROM
		(
		SELECT t1.[CAPTURE_DATE1], t2.[SEG_CLASS_CODE] FROM
		(SELECT DISTINCT [CAPTURE_DATE1] FROM [dbo].[RASP]) t1,  (SELECT DISTINCT [SEG_CLASS_CODE] FROM [dbo].[CLASS]) t2
		) mt,
			(
				SELECT  
					[FLT_NUMSH]
					, [DIRECTION]
					, [CAPTURE_DATE1]
				FROM (
						SELECT 
							 t1.[AIRLINE_CODESH] + '-' + CAST(t1.[FLT_NUMSH] as VARCHAR(5)) [FLT_NUMSH]
							 , CASE 
										WHEN t1.[LEG_ORIG] = 'SVO' and t1.[LEG_DEST]= 'ASF' THEN 'Москва-Астрахань'
										WHEN t1.[LEG_ORIG] = 'SVO' and t1.[LEG_DEST] = 'AER' THEN 'Москва-Сочи'
										WHEN t1.[LEG_ORIG] = 'ASF' and t1.[LEG_DEST] = 'SVO' THEN 'Астрахань-Москва'
										WHEN t1.[LEG_ORIG] = 'AER' and t1.[LEG_DEST] = 'SVO' THEN 'Сочи-Москва'
										ELSE 'UNKNOWN'
									END [DIRECTION]	
							  , t1.[EFFV_DATE]
							  , t1.[DISC_DATE]
							  , t1.[FREQ]      
							  , t1.[CAPTURE_DATE1]
							  , DATEPART(weekday, (t1.[CAPTURE_DATE1])) [DN]
							  , 
								CASE 
									WHEN t1.[CAPTURE_DATE1] >= t1.[EFFV_DATE] and t1.[CAPTURE_DATE1] <= t1.[DISC_DATE] and CHARINDEX(CAST(DATEPART(weekday, (t1.[CAPTURE_DATE1])) as varchar(1)), t1.[FREQ], 1) > 0 THEN 1
									ELSE 0
								END [FLY_EXISTS]
		
						FROM 
							[dbo].[RASP] t1
					) t
				WHERE [FLY_EXISTS] = 1
	) t1
	)mt
LEFT JOIN (
SELECT 
	t.[SDAT_S]
	, t.DT_KEY
	, t.[DD]
	, t.[SEG_CLASS_CODE]	
	, t.[SALES]
	, t.[AVG_SALES]
	, t.[DIRECTION]
	, t.[SDAT_S_P]
	, t.[DD_P]
	, ISNULL(t.[F_COUNT], 0) [F_COUNT]
	, CASE
		WHEN t.[F_COUNT] <> 0 THEN CAST(t.[AVG_SALES] AS numeric(10,2)) / CAST(t.[F_COUNT] AS numeric(10,2))
		ELSE CAST(t.[AVG_SALES] AS numeric(10,2))
	END [AVG_SALES_FLY]

FROM 
	(
		SELECT DISTINCT
			t1.[SDAT_S]
			, t1.DT_KEY
			, t1.[DD]
			, t1.[SEG_CLASS_CODE]			
			, t1.[SALES]
			, CASE 
				WHEN ISNULL(t2.[SALES], 0) = 0 THEN t1.[SALES]
				ELSE (t1.[SALES] + t2.[SALES]) / 2 
			END [AVG_SALES]
			, t1.[DIRECTION]
			, DATEADD(YEAR, 1, t1.[SDAT_S]) [SDAT_S_P]
			, DATEADD(YEAR, 1, t1.[DD]) [DD_P]
			, t3.[F_COUNT]
		FROM 
			(
			SELECT 
				[SDAT_S]
				, CASE 
					WHEN YEAR([SDAT_S]) = 2018 THEN [SDAT_S]
					WHEN YEAR([SDAT_S]) = 2019 THEN DATEADD(YEAR, -1, [SDAT_S]) 		
				END DT_KEY		
				, CASE 
					WHEN YEAR([DD]) = 2018 THEN [DD]
					WHEN YEAR([DD]) = 2019 THEN DATEADD(YEAR, -1, [DD]) 		
				END DD_KEY		
				, [DD]	
				, [SEG_CLASS_CODE]
				, SUM([SALES]) [SALES]
				, [DIRECTION]
			FROM 
				[dbo].[v_sales] 
			WHERE 
				[SALES] <> 0
				and [SDAT_S] >= '2018-01-01'		
			GROUP BY
				[SDAT_S]
				, [DD]	
				, [SEG_CLASS_CODE]	
				, [DIRECTION]
			) t1
		LEFT JOIN 
				(
				SELECT 
				[SDAT_S]		
				, [DD]	
				, [SEG_CLASS_CODE]				
				, SUM([SALES]) [SALES]
				, [DIRECTION]
			FROM 
				[dbo].[v_sales] 
			WHERE 
				[SALES] <> 0
		
				and [SDAT_S] >= '2018-01-01'
			GROUP BY
				[SDAT_S]
				, [DD]	
				, [SEG_CLASS_CODE]				
				, [DIRECTION]
				) t2 ON t2.[SDAT_S] = t1.[DT_KEY] and t2.[DD] = t1.[DD_KEY] and t2.[SEG_CLASS_CODE]=t1.[SEG_CLASS_CODE] and t2.[DIRECTION]=t1.[DIRECTION]

		LEFT JOIN (
					SELECT  
						 [CAPTURE_DATE1]
						 , [DIRECTION]
						 , SUM([FLY_EXISTS]) [F_COUNT]
					FROM (
							SELECT 
								 t1.[AIRLINE_CODESH] + '-' + CAST(t1.[FLT_NUMSH] as VARCHAR(5)) [FLT_NUMSH]
								 , CASE 
											WHEN t1.[LEG_ORIG] = 'SVO' and t1.[LEG_DEST]= 'ASF' THEN 'Москва-Астрахань'
											WHEN t1.[LEG_ORIG] = 'SVO' and t1.[LEG_DEST] = 'AER' THEN 'Москва-Сочи'
											WHEN t1.[LEG_ORIG] = 'ASF' and t1.[LEG_DEST] = 'SVO' THEN 'Астрахань-Москва'
											WHEN t1.[LEG_ORIG] = 'AER' and t1.[LEG_DEST] = 'SVO' THEN 'Сочи-Москва'
											ELSE 'UNKNOWN'
										END [DIRECTION]	
								  , t1.[EFFV_DATE]
								  , t1.[DISC_DATE]
								  , t1.[FREQ]      
								  , t1.[CAPTURE_DATE1]
								  , DATEPART(weekday, (t1.[CAPTURE_DATE1])) [DN]
								  , 
									CASE 
										WHEN t1.[CAPTURE_DATE1] >= t1.[EFFV_DATE] and t1.[CAPTURE_DATE1] <= t1.[DISC_DATE] and CHARINDEX(CAST(DATEPART(weekday, (t1.[CAPTURE_DATE1])) as varchar(1)), t1.[FREQ], 1) > 0 THEN 1
										ELSE 0
									END [FLY_EXISTS]
		
							FROM 
								[dbo].[RASP] t1
						) t
					where [FLY_EXISTS] = 1
					GROUP BY
						 [CAPTURE_DATE1]
						 , [DIRECTION]
					) t3 ON t3.[CAPTURE_DATE1] = DATEADD(YEAR, 1, t1.[DD]) and  t3.[DIRECTION] = t1.[DIRECTION]
		)t
	) t1 ON t1.[SDAT_S_P] = mt.[SDAT_S] and t1.[DD_P]=mt.[DD] and t1.[DIRECTION]=mt.[DIRECTION] and t1.[SEG_CLASS_CODE]=mt.[SEG_CLASS_CODE]
LEFT JOIN (
			SELECT DISTINCT 
				  [SSCL1]
				  ,[SEG_CLASS_CODE]      
			  FROM [dbo].[CLASS]
			) t2 ON mt.[SEG_CLASS_CODE] = t2.[SEG_CLASS_CODE]
WHERE t1.[AVG_SALES_FLY] <> 0



GO


