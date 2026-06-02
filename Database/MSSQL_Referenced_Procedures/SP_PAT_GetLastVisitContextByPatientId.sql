CREATE PROCEDURE [dbo].[SP_PAT_GetLastVisitContextByPatientId]
   @PatientId INT=NULL
AS
/*
Change Log

FileName: SP_PAT_GetLastVisitContextByPatientId
CreatedBy: Sud,9Sep'21--To get latest visit COntext.

Example: EXEC SP_PAT_GetLastVisitContextByPatientId 5
Description:
			This SP will return the Latest Patient Visit Context,
			We have other similar functions as well, but none of them seem to give consistant result.
History:
S.N				Name						Remarks
1.			  Sud,9Sep'21					initial Draft
2.			  Krishna,13thApril'23	        Read Scheme and PrieCategoryId and 
											return IsCurrentlyAdmitted as Boolean
*/
BEGIN
  Select vis.PatientId, vis.PatientVisitId, vis.VisitCode , vis.SchemeId, vis.PriceCategoryId,
	vis.VisitDate, 
	vis.VisitType, vis.DepartmentId, vis.PerformerId, 
	Case WHEN adm.AdmissionStatus is null then CONVERT(BIT,0)
	     when adm.AdmissionStatus = 'discharged' then CONVERT(BIT,0)
		 else CONVERT(BIT,1) end as IsCurrentlyAdmitted,
		 Convert(Date,adm.DischargeDate) 'DischargeDate'
		  from 
		  (
		  SELECT 
			 ROW_NUMBER() OVER (
			PARTITION BY patientid
			ORDER BY PatientVisitId desc  --to get latest first, we need to order by visitid descending
			 ) row_num,
			 PatientId, PatientVisitId,VisitCode, Convert(Date,VisitDate) 'VisitDate', 
			 VisitType, DepartmentId, PerformerId, SchemeId, PriceCategoryId

		  FROM  PAT_PatientVisits
		  Where PatientId=@PatientId AND BillingStatus != 'returned'
		  ) vis
		  left join ADT_PatientAdmission adm 
		  on vis.PatientVisitId=adm.PatientVisitId
	where row_num=1
END