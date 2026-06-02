CREATE PROCEDURE [dbo].[SP_LAB_GetAllSmsApplicableTests] 
	@FromDate DATE,
	@ToDate DATE
  
AS
/*
SP Name:	SP_LAB_GetAllSmsApplicableTests
Author:		Krishna Bogati/Sanjit Raj Shakya
CreatedOn:	2021-12-22
Remarks:	Created SP to Replace Linq Query from API in Lab Controller
Exec Example: EXEC SP_LAB_GetAllSmsApplicableTests @FromDate = '2021-01-01', @ToDate = '2021-12-22'
*/
BEGIN
	
	DECLARE @CovidTestName VARCHAR(1000) = '';
	DECLARE @VerificationParameter VARCHAR(1000) = '';
	DECLARE @IsVerificationRequired BIT = 0;
	DECLARE @VerificationLevel INT = 0;
	
	SELECT TOP(1)  @CovidTestName =  JSON_VALUE(ParameterValue, '$.DisplayName') FROM CORE_CFG_Parameters
	WHERE ParameterGroupName = 'common' AND ParameterName = 'CovidTestName'

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
		ISNULL(LR.IsSmsSend,0) as IsSmsSend, 
		LR.IsVerified, 
		LTCR.Value AS Result, 
		ISNULL(LR.IsFileUploaded,0) as IsFileUploaded
	FROM 
		LAB_TestRequisition AS LR
		INNER JOIN PAT_Patient AS P ON LR.PatientId = (P.PatientId)
		INNER JOIN LAB_LabTests AS LT ON LR.LabTestId = LT.LabTestId
		INNER JOIN LAB_TXN_TestComponentResult AS LTCR ON LR.RequisitionId = LTCR.RequisitionId
	WHERE 
		LT.SmsApplicable = 1 AND 
		LT.LabTestName = @CovidTestName AND
		LR.OrderStatus IN ('report-generated','result-added') AND
		((@IsVerificationRequired = 1 AND LR.IsVerified = 1) OR @IsVerificationRequired = 0) AND
		LTCR.Value IN ('positive','negative') AND
		LR.IsActive = 1 AND
		CONVERT(Date, LR.CreatedOn) BETWEEN @FromDate AND @ToDate
END