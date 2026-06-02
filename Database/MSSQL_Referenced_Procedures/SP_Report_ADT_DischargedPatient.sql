CREATE PROCEDURE [dbo].[SP_Report_ADT_DischargedPatient] 
	@FromDate Date=null ,
	@ToDate Date=null	
AS
/*
FileName: [SP_Report_ADT_DischargedPatient]
CreatedBy/date: Nagesh/Sud (upto 2018-08-21) 
Description: to get the count of total discharged patient between Given Date
Remarks:    Removed TotalAdmittedCount for now, add it later if needed.
Change History
S.No.    UpdatedBy/Date                        Remarks
1.     Nagesh/Sud (upto 2018-08-21)             Revised
2.     Sud/8Aug'21                              Handled Admitting Doctor non-mandatory case.
*/

BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN 
			select 
			  (Cast(ROW_NUMBER() OVER (ORDER BY  DischargeDate desc)  as int)) as SN,
			  	P.FirstName+ISNULL(' '+P.MiddleName,'')+' '+ P.LastName AS PatientName,
		      --(P.Firstname+''+P.LastName) 'PatientName',
              convert(varchar(20),CONVERT(date,DischargeDate)) 'DischargedDate', 
              convert(varchar(20),CONVERT(date,AdmissionDate)) 'AdmissionDate',
			  ISNULL(E.Salutation+' ','')+ E.FirstName+ISNULL(' '+E.MiddleName,'')+' '+ E.LastName 'AdmittingDoctor',
              --(E.FirstName+' '+E.LastName) 'AdmittingDoctor',
              A.PatientVisitId 'VisitId',
			  V.VisitCode 'IpNumber',
			  P.PatientCode 'HospitalNumber',
			  A.PatientId
		    from ADT_PatientAdmission A join PAT_PatientVisits V
                on A.PatientVisitId = V.PatientVisitId
               left join EMP_EMPLOYEE E on A.AdmittingDoctorId= E.EmployeeId 
               Join PAT_Patient P on P.PatientId=V.PatientId
		    where A.AdmissionStatus='discharged' and CONVERT(date,DischargeDate) between @FromDate and @ToDate
			Order By convert(varchar(20),CONVERT(date,DischargeDate)) desc
   --         union all
   --         select  NULL,NULL,NULL,'','Total Discharged Count ',Count('PatientVisitId'),null
   --         from ADT_PatientAdmission 
			--where AdmissionStatus='discharged' and CONVERT(date,DischargeDate) between @FromDate and @ToDate
	
	END	
END