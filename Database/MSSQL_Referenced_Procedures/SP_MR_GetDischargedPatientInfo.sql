CREATE PROCEDURE [dbo].[SP_MR_GetDischargedPatientInfo]
      @FromDate DATE, @ToDate Date
AS
/*
SP Name:SP_MR_GetDischargedPatientInfo
Created: Sud/01Feb'23
Description: Get dischargedpatient information for Medical Record
Remarks:	
Exec Example: EXEC SP_MR_GetDischargedPatientInfo '2022-01-01','2022-01-31'
CHANGE HISTORY:
1. Sud/01Feb'23			Created
2. Nirmala/25Sep'23     Fetch ICDCode

*/
BEGIN
--Create a Temp table to store Latest PatientBedInfoId of each PatientVisitId (i.e: AdmittedVisits)--
IF OBJECT_ID('tempdb.dbo.#MR_PatientLatestBedInfo', 'U') IS NOT NULL
DROP TABLE #MR_PatientLatestBedInfo
SELECT 
	PatientVisitId, 
	MAX(PatientBedInfoId) as LatestPatientBedInfoId
INTO #MR_PatientLatestBedInfo
FROM 
	ADT_TXN_PatientBedInfo WITH(NOLOCK)
GROUP BY PatientVisitId
SELECT 
	vis.VisitCode,
	vis.PatientVisitId,
	vis.PatientId,
	adm.PatientAdmissionId,
	adm.AdmissionDate AS 'AdmittedDate',
	adm.DischargeDate AS 'DischargedDate',
	adm.DischargedBy AS DischargedBy, --Taking ID since it is taking ID in the LINQ
	pat.PatientCode,
	adm.AdmittingDoctorId,
	admDocEmp.FullName AS AdmittingDoctorName,
	pat.Address,
	adm.AdmissionStatus,
	adm.BillStatusOnDischarge,
	pat.ShortName as Name,
	pat.DateOfBirth,
	pat.PhoneNumber,
	pat.Gender,
	dischSumm.IsSubmitted AS IsSubmitted,
	adm.IsPoliceCase,
	ISNULL(dischSumm.DischargeSummaryId,0) AS DischargeSummaryId,
	adm.IsInsurancePatient,
	mr.MedicalRecordId AS MedicalRecordId,
	dept.DepartmentName AS Department,
	adm.CareOfPersonName AS GuardianName,
	adm.CareOfPersonRelation AS GuardianRelation,
	0 AS IsSelected,  --Hardcoded False since it's used only in client side	
	bedInfo.BedId,
    bedInfo.PatientBedInfoId,
    bedInfo.WardId,
	ward.WardName AS Ward,
	bedInfo.BedFeatureId,
	bedInfo.Action,
    bedInfo.StartedOn,
	bf.BedFeatureName 'BedFeature',
	bed.BedCode,
	bed.BedNumber,
	Diagnosis.ICDCode
from 
ADT_PatientAdmission adm WITH(NOLOCK)
	INNER JOIN PAT_PatientVisits vis WITH(NOLOCK) on adm.PatientVisitId=vis.PatientVisitId
	INNER JOIN PAT_Patient pat WITH(NOLOCK)  on adm.PatientId=pat.PatientId
	INNER JOIN #MR_PatientLatestBedInfo  lastBedInfo WITH(NOLOCK) ON vis.PatientVisitId = lastBedInfo.PatientVisitId
	INNER JOIN ADT_TXN_PatientBedInfo bedInfo WITH(NOLOCK) ON lastBedInfo.LatestPatientBedInfoId = bedInfo.PatientBedInfoId AND vis.PatientVisitId = bedInfo.PatientVisitId
	INNER JOIN ADT_MST_Ward ward on bedInfo.WardId = ward.WardID
	INNER JOIN ADT_Bed bed on bedInfo.BedId=bed.BedID
	INNER JOIN ADT_MST_BedFeature bf on bedInfo.BedFeatureId=bf.BedFeatureId
	LEFT JOIN EMP_Employee admDocEmp on adm.AdmittingDoctorId=admDocEmp.EmployeeId
	LEFT JOIN ADT_DischargeSummary dischSumm ON dischSumm.PatientVisitId = adm.PatientVisitId
	LEFT JOIN MR_RecordSummary mr WITH(NOLOCK) on adm.PatientVisitId=mr.PatientVisitId
	LEFT JOIN MST_Department dept on vis.DepartmentId=dept.DepartmentId
	LEFT JOIN (Select STRING_AGG(ICD.ICD10Code, ', ') AS ICDCode,diag.PatientVisitId from MR_TXN_Inpatient_Diagnosis 
    diag INNER JOIN MST_ICD10 ICD on diag.ICD10ID = ICD.ICD10ID group by diag.PatientVisitId) AS Diagnosis
	ON adm.PatientVisitId = Diagnosis.PatientVisitId
WHERE 
adm.AdmissionStatus='discharged'
  AND Convert(Date,adm.DischargeDate) between @FromDate and @ToDate
ORder by adm.DischargeDate desc
END