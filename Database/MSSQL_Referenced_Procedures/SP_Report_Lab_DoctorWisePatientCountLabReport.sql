--Altering SP_Report_Lab_DoctorWisePatientCountLabReport SP
--changed RequestedBy to PrescriberId 
CREATE PROCEDURE [dbo].[SP_Report_Lab_DoctorWisePatientCountLabReport]   
@FromDate datetime = NULL,  
@ToDate datetime = NULL  
AS  
  
  
/*  
FileName: [SP_Report_Lab_DoctorWisePatientCountLabReport]  '2019-12-02','2019-12-02'  
CreatedBy/date: Dinesh 1st Jan 2020  
Description: to get the total count of test conducted   
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1       Dinesh					Hams Requirement(to identify the no of patient entered from op/ip/er)  
2		Krishna,9thJun'22		changed RequestedBy to PrescriberId
*/  
BEGIN  
  IF (@FromDate IS NOT NULL OR @ToDate IS NOT NULL OR LEN(@FromDate) > 0 OR LEN(@ToDate) > 0)  
  BEGIN  
    
  
  
select (Cast(ROW_NUMBER() OVER (ORDER BY  FullName asc)  AS int)) AS SN,FullName 'Doctor',Sum(OP) OP ,Sum(IP) IP,SUm(Emergency) Emergency from (  
select  
  
COALESCE(case   
when (visit.VisitType in ('outpatient')) then count(distinct(bt.PatientId))  
END ,0) as OP,  
COALESCE(case   
when (visit.VisitType in ('inpatient')) then count(distinct(bt.PatientId))  
END ,0) as IP,  
COALESCE(case   
when (visit.VisitType in ('emergency')) then count(distinct(bt.PatientId))  
END ,0) as 'Emergency'  
  
,bt.PrescriberId,em.FullName from BIL_TXN_BillingTransactionItems bt  
join BIL_MST_ServiceDepartment sd   
on bt.ServiceDepartmentId=sd.ServiceDepartmentId  
join PAT_PatientVisits visit on visit.PatientVisitId=bt.PatientVisitId  
join EMP_Employee em on em.EmployeeId=bt.PrescriberId  
where convert(date,bt.CreatedOn) = @fromdate and bt.PrescriberId is not null and sd.IntegrationName='LAB'  
group by bt.PrescriberId,em.FullName,visit.VisitType  
) vt group by vt.PrescriberId,vt.FullName  
  
  END  
END