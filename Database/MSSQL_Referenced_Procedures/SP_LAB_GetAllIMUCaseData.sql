CREATE PROCEDURE [dbo].[SP_LAB_GetAllIMUCaseData] 
	@FromDate DATETIME,
	@ToDate DATETIME
  
AS
/*
SP Name:	[SP_LAB_GetAllIMUCaseData]
Author:		Dev Narayan Chaudhary
CreatedOn:	2022-03-28
Remarks:	Stored Procedure That Provides All Tests List For IMU Upload
Exec Example: EXEC SP_LAB_GetAllIMUCaseData @FromDate = '2022-02-01', @ToDate = '2022-03-28'
*/
BEGIN
	
	DECLARE @TestCSV VARCHAR(1000) = '';
	DECLARE @VerificationParameter VARCHAR(1000) = '';
	DECLARE @IsVerificationRequired BIT = 0;
	DECLARE @VerificationLevel INT = 0;
	
	declare @json varchar(max) = (select ParameterValue FROM CORE_CFG_Parameters
	WHERE ParameterGroupName = 'LAB' AND ParameterName = 'LabIMUenabledTests')
	SELECT  @TestCSV = STRING_AGG(ImuTestList.DanpheLabTestName,',') FROM OPENJSON(@json) 
		WITH 
		(
		    DanpheLabTestName VARCHAR(100)
		) AS ImuTestList 

	SELECT TOP(1)  @VerificationParameter = ParameterValue FROM CORE_CFG_Parameters
	WHERE ParameterGroupName = 'lab' AND ParameterName = 'LabReportVerificationNeededB4Print'

	SET @IsVerificationRequired = CAST (JSON_VALUE(@VerificationParameter, '$.EnableVerificationStep') AS BIT)
	SET @VerificationLevel = CAST (JSON_VALUE(@VerificationParameter, '$.VerificationLevel') AS INT)


	SELECT 
		LR.RequisitionId, 
		P.ShortName AS PatientName, 
		LR.LabTestName, 
		LR.SampleCollectedOnDateTime, 
		P.DateOfBirth, 
		P.Age, 
		P.Gender, 
		P.PatientCode, 
		ISNULL(P.PhoneNumber,'') as PhoneNumber, 
		LTCR.Value AS Result, 
		ISNULL(LR.IsUploadedToIMU,0) as IsFileUploaded
	FROM 
		LAB_TestRequisition AS LR
		INNER JOIN PAT_Patient AS P ON LR.PatientId = (P.PatientId)
		INNER JOIN LAB_LabTests AS LT ON LR.LabTestId = LT.LabTestId
		INNER JOIN LAB_TXN_TestComponentResult AS LTCR ON LR.RequisitionId = LTCR.RequisitionId
	WHERE 
		LT.LabTestName IN (SELECT value FROM STRING_SPLIT(@TestCSV,',')) AND
		LR.OrderStatus IN ('report-generated','result-added') AND
		((@IsVerificationRequired = 1 AND LR.IsVerified = 1) OR @IsVerificationRequired = 0) AND
		LTCR.Value IN ('positive','negative') AND
		LR.IsActive = 1 AND
		CONVERT(Date, LR.CreatedOn) BETWEEN @FromDate AND @ToDate
END