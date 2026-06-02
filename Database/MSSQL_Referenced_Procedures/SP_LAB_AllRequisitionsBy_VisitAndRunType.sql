-- =============================================
-- Author:		<Anish Bhattarai>
-- Updated date: <1 Junly 2021>
-- Description:	<Description,,>
-- exec [SP_LAB_AllRequisitionsBy_VisitAndRunType] 1,397,'2023-01-02'
-- =============================================
/*
S.N        Auther/Date                       Description
1.         Dev Narayan 2Jan'2023             LabTypeWise separate sequence no generation logic added.
*/
CREATE PROCEDURE [dbo].[SP_LAB_AllRequisitionsBy_VisitAndRunType] @GroupingIndex INT
	,@PatientId INT
	,@SampleDate DATE
	,@LabTypeName VARCHAR(30)
AS
BEGIN
	DECLARE @startDate DATE;
	DECLARE @endDate DATE;
	DECLARE @rangeType VARCHAR(20);

	SELECT @rangeType = (
			CASE 
				WHEN settingRow.ResetDaily = 1
					THEN 'day'
				WHEN settingRow.ResetMonthly = 1
					THEN 'month'
				WHEN settingRow.ResetYearly = 1
					THEN 'year'
				ELSE ''
				END
			)
	FROM (
		SELECT TOP (1) *
		FROM Lab_MST_RunNumberSettings
		WHERE RunNumberGroupingIndex = @GroupingIndex
		) settingRow;

	SELECT @startDate = dateRange.StartDate
		,@endDate = dateRange.EndDate
	FROM (
		SELECT *
		FROM FN_Common_GetNepStartEndDate_ByRangeName(@SampleDate, @rangeType)
		) dateRange;

	SELECT MAX(LastSampleNumber) + 1 AS LatestSampleCode
	FROM (
		SELECT LastSampleNumber
		FROM (
			SELECT MAX(SampleCode) AS LastSampleNumber
			FROM LAB_TestRequisition req
			JOIN Lab_MST_RunNumberSettings sett ON (LOWER(req.VisitType) = LOWER(sett.VisitType))
				AND (LOWER(req.RunNumberType) = LOWER(sett.RunNumberType))
				AND (req.HasInsurance = sett.UnderInsurance)
			WHERE sett.RunNumberGroupingIndex = @GroupingIndex
				AND SampleCode IS NOT NULL
				AND req.LabTypeName = @LabTypeName
				AND SampleCreatedOn IS NOT NULL
				AND CONVERT(DATE, SampleCreatedOn) BETWEEN @startDate
					AND @endDate
			GROUP BY req.SampleCode
			) AS ReqList
		
		UNION
		
		(
			SELECT 0 AS LastSampleNumber
			)
		) allReqList;

	SELECT DISTINCT TOP (1) SampleCode AS SampleNumber
		,BarCodeNumber
		,SampleCodeFormatted
		,0 AS IsSelected
		,SampleCreatedOn AS SampleDate
	FROM LAB_TestRequisition req
	JOIN Lab_MST_RunNumberSettings sett ON (LOWER(req.VisitType) = LOWER(sett.VisitType))
		AND (LOWER(req.RunNumberType) = LOWER(sett.RunNumberType))
		AND (req.HasInsurance = sett.UnderInsurance)
	WHERE sett.RunNumberGroupingIndex = @GroupingIndex
		AND SampleCode IS NOT NULL
		AND req.LabTypeName = @LabTypeName
		AND SampleCreatedOn IS NOT NULL
		AND CONVERT(DATE, SampleCreatedOn) BETWEEN @startDate
			AND @endDate
		AND req.PatientId = @PatientId
		AND req.BarCodeNumber IS NOT NULL
	ORDER BY BarCodeNumber DESC;
END