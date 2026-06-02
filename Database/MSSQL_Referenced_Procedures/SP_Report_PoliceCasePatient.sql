CREATE PROCEDURE [dbo].[SP_Report_PoliceCasePatient] 
	@FromDate Date=null ,
	@ToDate Date=null	
AS
/*
FileName: [SP_Report_PoliceCasePatient]
CreatedBy/date: Anjana (2020-09-30) 
Description: to get the count of total police case patient between Given Date

Change History
S.No.    UpdatedBy/Date                        Remarks
1.     Anjana (2020-09-30)					Initial Draft
2.     Dev Narayan (2021-09-29)             Change police case codition check in sp form database column 'isPoliceCase' to 'AdmissionCase'
*/

BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN 
			select 
			  (Cast(ROW_NUMBER() OVER (ORDER BY  DischargeDate desc)  as int)) as SN,
			  	P.ShortName,
		      --(P.Firstname+''+P.LastName) 'PatientName',
              convert(varchar(20),CONVERT(date,DischargeDate)) 'DischargedDate', 
              convert(varchar(20),CONVERT(date,AdmissionDate)) 'AdmissionDate',
			  V.VisitCode 'IpNumber',
			  P.PatientCode 'HospitalNumber',
			  A.PatientId,
			  A.AdmissionStatus
		    from ADT_PatientAdmission A join PAT_PatientVisits V
                on A.PatientVisitId = V.PatientVisitId
               Join PAT_Patient P on P.PatientId=V.PatientId
		    where A.AdmissionCase LIKE '%Police_Case%' and CONVERT(date,AdmissionDate) between @FromDate and @ToDate
			Order By convert(varchar(20),CONVERT(date,AdmissionDate)) desc
	
	END	
END