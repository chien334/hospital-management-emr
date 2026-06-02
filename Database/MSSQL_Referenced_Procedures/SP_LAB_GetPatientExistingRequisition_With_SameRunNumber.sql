-- =============================================
-- Author:		<Anish>
-- Create date: <2 July>
-- Description:	<Get the existing requisition with same run number data>
-- =============================================
CREATE PROCEDURE SP_LAB_GetPatientExistingRequisition_With_SameRunNumber
	@GroupingIndex int,
	@SampleDate Date,
	@SampleCode int,
	@PatientId Bigint
AS
BEGIN
	
	DECLARE @startDate DATE;
	DECLARE @endDate DATE;
	DECLARE @rangeType VARCHAR(20);


	SELECT @rangeType=(CASE 
						WHEN settingRow.ResetDaily=1 
						THEN 'day'
						WHEN settingRow.ResetMonthly=1
						THEN 'month'
						WHEN settingRow.ResetYearly=1
						THEN 'year'
						ELSE ''
						END
						)FROM (SELECT TOP(1) * FROM Lab_MST_RunNumberSettings WHERE RunNumberGroupingIndex=@GroupingIndex) settingRow;

	SELECT @startDate=dateRange.StartDate,@endDate=dateRange.EndDate FROM (SELECT * FROM FN_Common_GetNepStartEndDate_ByRangeName(@sampleDate,@rangeType)) dateRange;

	SELECT * FROM LAB_TestRequisition req JOIN Lab_MST_RunNumberSettings sett 
		ON (LOWER(req.VisitType) = LOWER(sett.VisitType)) AND (LOWER(req.RunNumberType) = LOWER(sett.RunNumberType)) AND (req.HasInsurance=sett.UnderInsurance) 
		WHERE sett.RunNumberGroupingIndex=@GroupingIndex AND SampleCode IS NOT NULL AND (SampleCode=@SampleCode) AND req.PatientId=@PatientId
		AND SampleCreatedOn IS NOT NULL AND CONVERT(DATE,SampleCreatedOn) BETWEEN @startDate AND @endDate;
END