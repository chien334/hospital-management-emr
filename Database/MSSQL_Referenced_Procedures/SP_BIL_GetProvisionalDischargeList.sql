CREATE PROCEDURE SP_BIL_GetProvisionalDischargeList
AS
/*
FileName: SP_BIL_GetProvisionalDischargeList
Author/Date: Krishna, 5thSept'23
eg: exec SP_BIL_GetProvisionalDischargeList
Description: This SP will give the list of in-patients who are discharged provisionally but their discharge 
			 invoice is not generated.

Change History:
S.N.	UpdatedBy/Date                        Remarks  
1.	    Krishna,5thSept'23					  initial script
*/
BEGIN
SELECT 
	visit.VisitCode AS 'IpNumber',
	pat.PatientCode AS 'HospitalNumber',
	pat.ShortName AS 'PatientName',
	pat.Gender AS 'Gender',
	pat.DateOfBirth AS 'DateOfBirth',
	IIF(ISNULL(adm.CareOfPersonPhoneNo, '') <> '', CONCAT(pat.PhoneNumber, '/', adm.CareOfPersonPhoneNo), pat.PhoneNumber) AS 'Contacts',
	CONCAT(wardBedInfo.WardName, '/', wardBedInfo.BedCode) AS 'WardBed',
	dep.DepositBalance AS 'DepositAmount',
	adm.AdmissionDate AS 'AdmittedOn',
	adm.DischargeDate AS 'ProvisionalDischargedOn',
	emp.FullName AS 'ProvisionalDischargedBy',
	adm.DischargeRemarks AS 'Remarks',
	pat.PatientId,
	adm.DiscountSchemeId AS 'SchemeId',
	adm.PatientVisitId,
	visit.PriceCategoryId

FROM (SELECT AdmissionDate, DischargeDate, CareOfPersonPhoneNo, 
			 DischargeRemarks, PatientId, PatientVisitId, DischargedBy, DiscountSchemeId FROM ADT_PatientAdmission 
	  WHERE IsProvisionalDischarge = 1 
			AND IsProvisionalDischargeCleared = 0
			AND AdmissionStatus = 'discharged') adm
INNER JOIN PAT_PatientVisits visit ON adm.PatientVisitId = visit.PatientVisitId
INNER JOIN PAT_Patient pat ON adm.PatientId = pat.PatientId
LEFT JOIN (SELECT PatientId,(SUM(ISNULL(InAmount,0)) - SUM(ISNULL(OutAmount,0))) AS 'DepositBalance' FROM BIL_TXN_Deposit 
				GROUP BY PatientId) dep ON adm.PatientId = dep.PatientId
INNER JOIN EMP_Employee emp ON adm.DischargedBy = emp.EmployeeId
OUTER APPLY (SELECT ward.WardName,bed.BedCode FROM 
			 (SELECT TOP(1) BedId, WardId FROM ADT_TXN_PatientBedInfo 
			 WHERE PatientVisitId = adm.PatientVisitId ORDER BY PatientBedInfoId DESC) bedInfo
			 INNER JOIN ADT_Bed bed ON bedInfo.BedId = bed.BedID
			 INNER JOIN ADT_MST_Ward ward ON bedInfo.WardId = ward.WardID) wardBedInfo
ORDER BY adm.DischargeDate DESC
END