-- Create the stored procedure in the specified schema
CREATE PROCEDURE [dbo].[SP_ADT_GetAllAdmittedPatients]
    @AdmissionStatus VARCHAR(20) = 'admitted',
	@PatientVisitId INT NULL
AS
/*
SP Name:	SP_ADT_GetAllAdmittedPatients
Author:		Krishna Bogati/Sanjit Raj Shakya
CreatedOn:	2021-12-22
Remarks:	Created SP to Replace Linq Query from API in Admission Controller
Exec Example: EXEC SP_ADT_GetAllAdmittedPatients @@AdmissionStatus = 'admitted', @PatientVisitId = 0
CHANGE/HISTORY:
1. Krishna 13th,JAN'22				AdmissionDate changed to AdmittedDate(EMR:4762)

*/
BEGIN
    -- body of the stored procedure
    IF OBJECT_ID('tempdb.dbo.#latestBedInfos', 'U') IS NOT NULL
	DROP TABLE #latestBedInfos

	SELECT 
		PBI.PatientVisitId, 
		MAX(PBI.PatientBedInfoId) as LatestPatientBedInfoId
	INTO #latestBedInfos
	FROM 
		ADT_TXN_PatientBedInfo PBI
	GROUP BY PBI.PatientVisitId

	SELECT 
		visit.VisitCode,
		visit.PatientVisitId,
		adm.PatientId,
		adm.PatientAdmissionId,
		adm.AdmissionDate AS AdmittedDate,
		adm.DischargeDate,
		adm.DischargedBy,
		pat.PatientCode,
		adm.AdmittingDoctorId,
		ISNULL(doc.FullName, '') as AdmittingDoctorName,
		ISNULL(pat.Address,'') as Address,
		adm.AdmissionStatus,
		adm.BillStatusOnDischarge,
		pat.ShortName AS [NAME],
		pat.DateOfBirth,
		ISNULL(pat.PhoneNumber,'') as PhoneNumber,
		pat.Gender,
		summary.IsSubmitted,
		ISNULL(summary.DischargeSummaryId, 0) DischargeSummaryId,
		dep.DepartmentId,
		dep.DepartmentName AS Department,
		adm.CareOfPersonName AS GuardianName,
		adm.CareOfPersonRelation AS GuardianRelation,
		CASE
			WHEN adm.AdmissionCase = 'Police Case' Then 1
			ELSE 0
		END as IsPoliceCase,
		CASE WHEN adm.IsInsurancePatient IS NULL THEN 0 ELSE adm.IsInsurancePatient END as IsInsurancePatient,
		--Patient Bed Infos--
		PBI.BedId,
		PBI.PatientBedInfoId,
		PBI.WardId,
		PBI.BedFeatureId,
		PBI.StartedOn,
		PBI.BedOnHoldEnabled,
		PBI.ReceivedBy,
		WD.WardName AS Ward,
		B.BedFeatureName AS BedFeature,
		BED.BedCode,
		BED.BedNumber,
		UPPER(LEFT(PBI.Action,1))+LOWER(SUBSTRING(PBI.Action,2,LEN(PBI.Action))) AS Action

	FROM
		ADT_PatientAdmission adm
		INNER JOIN PAT_PatientVisits visit ON adm.PatientVisitId = visit.PatientVisitId
		INNER JOIN PAT_Patient pat ON pat.PatientId = adm.PatientId
		INNER JOIN MST_Department dep ON visit.DepartmentId = dep.DepartmentId
		INNER JOIN #latestBedInfos LBI ON visit.PatientVisitId = LBI.PatientVisitId
		INNER JOIN ADT_TXN_PatientBedInfo PBI ON LBI.LatestPatientBedInfoId = PBI.PatientBedInfoId AND visit.PatientVisitId = PBI.PatientVisitId
		INNER JOIN ADT_Bed BED ON PBI.BedId = BED.BedID
		INNER JOIN ADT_MST_Ward WD ON PBI.WardId = WD.WardID
		INNER JOIN ADT_MST_BedFeature B ON B.BedFeatureId = PBI.BedFeatureId
		LEFT JOIN ADT_DischargeSummary summary ON adm.PatientVisitId = summary.PatientVisitId
		LEFT JOIN EMP_Employee doc ON adm.AdmittingDoctorId = doc.EmployeeId
	WHERE 
		LOWER(adm.AdmissionStatus) = LOWER(@AdmissionStatus) AND
		(@PatientVisitId = 0 OR adm.PatientVisitId = @PatientVisitId)
	ORDER BY adm.AdmissionDate DESC
END