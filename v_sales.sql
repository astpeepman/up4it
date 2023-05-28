USE [AVIA]
GO

/****** Object:  View [dbo].[v_sales]    Script Date: 28.05.2023 17:11:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE VIEW [dbo].[v_sales]
WITH SCHEMABINDING
AS
--SELECT getdate() as [date]
SELECT
	t.[SDAT_S]  
	, [SDAT_S_PD] 
	, t.[FLT_NUM]
	, t.[DD] 
	, t.[SSCL1] 
	, t.[SEG_CLASS_CODE]
	, t.[FCLCLD]
	, t.[PASS_BK]
	, t.[SA]
	, t.[AU]
	, t.[PASS_DEP]
	, t.[NS]
	, t.[SALES_DAY_NUM]
	, t.[PASS_BK_PD] 	
	, CASE	
		WHEN [SALES_DAY_NUM] = 1 THEN t.[PASS_BK]
		WHEN [SALES_DAY_NUM] in (0,2) THEN t.[PASS_BK] - t.[PASS_BK_PD]
		WHEN [SALES_DAY_NUM] = 3 THEN 0
	  END [SALES]
	, DATEDIFF(DAY, t.[SDAT_S], t.[DD]) [DD_NUM]	
	, t.[DIRECTION]
	, [FLT_NORM]
FROM	
	(
	SELECT 
		t1.[SDAT_S]  
		, DATEADD(DAY, -1, t1.[SDAT_S]) [SDAT_S_PD] 
		, t1.[FLT_NUM]
		, t1.[DD] -- ���� ������
		, t1.[SSCL1]  --  ��� ������ Y - ������; � - 
		, t1.[SEG_CLASS_CODE] -- ����� ������������, ��� ����� 
		, t1.[FCLCLD] -- ������� �������� ������ ���������	
		, t1.[PASS_BK]
		, t1.[SA] --���������� ������ ��������� ��� ������������
		, t1.[AU] -- ���-�� ���� ��������� � ������� �� ������ �� ���� ������������
		, t1.[PASS_DEP] --���������� ����������
		, t1.[NS] --���-�� �� ����������
		, CASE 
				WHEN t2.[SDAT_S] is  not null THEN 1
				WHEN t1.[SDAT_S] = t1.[DD] THEN 2
				WHEN t1.[SDAT_S] > t1.[DD] THEN 3
				ELSE 0
			END [SALES_DAY_NUM]
		, ISNULL(t3.[PASS_BK], 0) [PASS_BK_PD] 	
		, CASE 
				WHEN t1.[SORG] = 'SVO' and t1.[SDST] = 'ASF' THEN '������-���������'
				WHEN t1.[SORG] = 'SVO' and t1.[SDST] = 'AER' THEN '������-����'
				WHEN t1.[SORG] = 'ASF' and t1.[SDST] = 'SVO' THEN '���������-������'
				WHEN t1.[SORG] = 'AER' and t1.[SDST] = 'SVO' THEN '����-������'
				ELSE 'UNKNOWN'
			END [DIRECTION]	
		, t1.[SAK] + '-' + CAST(t1.[FLT_NUM] as varchar(5)) [FLT_NORM]

	FROM 
		[dbo].[CLASS] t1
	LEFT JOIN [dbo].[v_first_sales]  t2 ON  t2.[SDAT_S] = t1.[SDAT_S] and t2.[FLT_NUM]=t1.[FLT_NUM] and t2.[DD]=t1.[DD] and t2.[SEG_CLASS_CODE]=t1.[SEG_CLASS_CODE]
	LEFT JOIN  [dbo].[CLASS] t3 ON t3.[SDAT_S] = DATEADD(DAY, -1, t1.[SDAT_S]) and t3.[FLT_NUM]=t1.[FLT_NUM] and t3.[DD]=t1.[DD] and t3.[SEG_CLASS_CODE]=t1.[SEG_CLASS_CODE]		
	) t



GO


