CREATE PROCEDURE [dbo].[SP_GetVisitListForOPD]
		@FromDate DATETIME=null ,
		@ToDate DATETIME=null
		--@SearchText varchar(100)
AS
/*
FileName: [SP_GetVisitListForOPD]
CreatedBy/date: Anjana/2020-06-23
Description: to get list of outpatient 

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Anjana/2020-06-23					Initial Draft
2.      Anjana/2020-07-09					Updated HasVitals to IsTriaged for OPD Triage
3.		Krishna/2Jun'22						changed ProviderName to PerformerName, ProviderId to PerformerId 
4.      Santosh/1st Aug'23                  AdmissionDate and DepartmentName is added for Investigation Results
*/
BEGIN
SELECT
  pat.PatientId,
  pat.PatientCode,
  pat.ShortName,
  pat.DateOfBirth,
  pat.PhoneNumber,
  pat.Gender,
  pat.Address,
  pat.Age,
  adm.AdmissionDate AS AdmittedDate,
  vis.VisitDate,
  vis.VisitTime,
  vis.VisitType,
  vis.PatientVisitId,
  vis.PerformerName,
  vis.PerformerId,
  dept.DepartmentName,
  vis.AppointmentType,

 CASE WHEN vit.PatientVisitId IS NOT NULL THEN 1 ELSE 0 END AS 'IsTriaged'
FROM 
 PAT_Patient pat 
     INNER JOIN
 PAT_PatientVisits vis
    ON pat.PatientId= vis.PatientId
	INNER JOIN MST_Department dept ON vis.DepartmentId = dept.DepartmentId
LEFT JOIN
  (SELECT DISTINCT PatientVisitId 
   FROM 
    CLN_KV_PatientClinical_Info )
   vit
  ON vis.PatientVisitId = vit.PatientVisitId
  	Left JOIN ADT_PatientAdmission adm ON  pat.PatientId = adm.PatientId AND vit.PatientVisitId = adm.PatientVisitId

 
WHERE  
vis.VisitType = 'outpatient'
AND vis.BillingStatus != 'cancel'
AND vis.BillingStatus != 'returned'

AND CONVERT(DATE, vis.CreatedOn) BETWEEN ISNULL(@FromDate,CONVERT(DATE, GETDATE())) AND ISNULL(@ToDate, Convert(DATE, GETDATE()))
END