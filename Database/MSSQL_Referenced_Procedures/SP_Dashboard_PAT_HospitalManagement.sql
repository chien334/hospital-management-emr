CREATE PROCEDURE SP_Dashboard_PAT_HospitalManagement @FromDate DATE = NULL
	,@ToDate DATE = NULL
AS
/*
 SP_Dashboard_PAT_HospitalManagement '2022-1-05'
FileName: [SP_Dashboard_PAT_HospitalManagement]
CreatedBy/date:Nirmala/2022-1-05
Description: .
Remarks:    A
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Nirmala/2022-1-05                created the script
*/
BEGIN
	SELECT 'OPD' 'Label'
		,count(PatientId) 'Count'
	FROM BIL_TXN_BillingTransactionItems
	WHERE ServiceDepartmentName LIKE '%OPD%'
		AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	
	UNION ALL
	
	SELECT 'Lab' 'Label'
		,count(PatientId) 'Count'
	FROM LAB_TestRequisition
	WHERE Orderstatus IN (
			'active'
			,'result-added'
			)
		AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	
	UNION ALL
	
	SELECT 'NewPatient' 'Label'
		,count(PatientId) 'Count'
	FROM PAT_Patient
	WHERE CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	
	UNION ALL
	
	SELECT 'Admission' 'Label'
		,count(patientId) 'Count'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'admitted'
		AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
	
	UNION ALL
	
	SELECT 'Discharge' 'Label'
		,count(patientId) 'Count'
	FROM ADT_PatientAdmission
	WHERE AdmissionStatus = 'discharged'
		AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate);
END