-- =============================================
-- Author:		<Anish>
-- Updated date: <2 July>
-- Description:	<Get the Duplicate Data by Sample Code>
-- =============================================
/*
S.N        Auther/Date                       Description
1.         Dev Narayan 2Jan'2023             LabTypeWise filter of sample code.
*/
CREATE PROCEDURE [dbo].[SP_LAB_AllRequisitionsBy_SampleCode] @sampleCode INT
	,@sampleDate DATE
	,@groupingIndex INT
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
		FROM FN_Common_GetNepStartEndDate_ByRangeName(@sampleDate, @rangeType)
		) dateRange;

	SELECT *
	FROM LAB_TestRequisition req
	JOIN Lab_MST_RunNumberSettings sett ON (LOWER(req.VisitType) = LOWER(sett.VisitType))
		AND (LOWER(req.RunNumberType) = LOWER(sett.RunNumberType))
		AND (req.HasInsurance = sett.UnderInsurance)
	WHERE sett.RunNumberGroupingIndex = @GroupingIndex
		AND req.LabTypeName = @LabTypeName
		AND (SampleCode = @sampleCode)
		AND SampleCreatedOn IS NOT NULL
		AND CONVERT(DATE, SampleCreatedOn) BETWEEN @startDate
			AND @endDate;
END