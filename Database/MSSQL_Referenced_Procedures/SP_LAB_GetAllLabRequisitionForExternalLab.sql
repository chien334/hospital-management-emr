CREATE PROCEDURE [dbo].[SP_LAB_GetAllLabRequisitionForExternalLab]
	@PatientName VARCHAR(50) = '',
	@HospitalCode VARCHAR(20) = '',
	@FromDate DATE,
	@ToDate DATE,
	@LabTestIdCSV VARCHAR(MAX),
	@VendorId INT,
	@ExternalLabStatus VARCHAR(40)= ''
AS
/*
Change History
S.No.    UpdatedBy/Date                        Remarks
1       DevN/13Sept'23                       Initial Draft to get all lab requisitions sent to external lab.
2       Santosh/13Sept'23                    ExternalLabStatus filter is added to the SP to get data accourding to the sample                                            status
*/
BEGIN
SELECT REQ.RequisitionId
	,PAT.ShortName AS 'PatientName'
	,VENDOR.VendorName
	,TEST.LabTestName AS 'TestName'
	,PAT.PatientCode AS 'HospitalNo'
	,REQ.ExternalLabSampleStatus
FROM (
	(
		SELECT RequisitionId
			,LabTestId
			,PatientId
			,ResultingVendorId
			,ExternalLabSampleStatus
		FROM LAB_TestRequisition WITH (NOLOCK)
		WHERE CONVERT(DATE, CreatedOn) BETWEEN @FromDate
				AND @ToDate AND ResultingVendorId = @VendorId
		) REQ 
	INNER JOIN (
		SELECT CONVERT(INT, VALUE) AS 'LabTestId'
		FROM STRING_SPLIT(@LabTestIdCSV, ',')
		WHERE RTRIM(value) <> ''
		) TestIds ON REQ.LabTestId = TestIds.LabTestId
	INNER JOIN Lab_MST_LabVendors VENDOR ON REQ.ResultingVendorId = VENDOR.LabVendorId
	INNER JOIN PAT_Patient PAT ON REQ.PatientId = PAT.PatientId
	INNER JOIN LAB_LabTests TEST ON TestIds.LabTestId = TEST.LabTestId
	)
WHERE (@PatientName = '' OR PAT.ShortName LIKE @PatientName + '%')
AND (@HospitalCode = '' OR PAT.PatientCode = @HospitalCode) AND (@ExternalLabStatus='' OR REQ.ExternalLabSampleStatus = @ExternalLabStatus )
END