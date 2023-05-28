USE [AVIA]
GO

/****** Object:  View [dbo].[v_first_sales]    Script Date: 28.05.2023 17:11:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[v_first_sales]
WITH SCHEMABINDING
AS
--SELECT getdate() as [date]
SELECT
	t1.[SDAT_S] 
	, t1.[FLT_NUM]
	, t1.[DD]
	, t1.[SEG_CLASS_CODE]
	, t2.[PASS_BK]
FROM (

		SELECT 
			MIN([SDAT_S]) [SDAT_S] 
			, [FLT_NUM]
			, [DD] -- дата вылета	
			, [SEG_CLASS_CODE] -- класс бронирования, тип места 		
		FROM 
			[dbo].[CLASS]		
		GROUP BY	
			[FLT_NUM]
			, [DD] 
			, [SEG_CLASS_CODE]	
		) t1
LEFT JOIN (
		SELECT 
			[SDAT_S]
			, [FLT_NUM]
			, [DD] -- дата вылета	
			, [SEG_CLASS_CODE] -- класс бронирования, тип места 		
			, [PASS_BK]
		FROM 
			[dbo].[CLASS]
		) t2 ON t2.[SDAT_S] = t1.[SDAT_S] and t2.[FLT_NUM]=t1.[FLT_NUM] and t2.[DD]=t1.[DD] and t2.[SEG_CLASS_CODE]=t1.[SEG_CLASS_CODE]
	


GO


