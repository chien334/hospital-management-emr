--Altering SP_Report_BIL_DoctorReferrals SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DoctorReferrals]   
 @FromDate DateTime=null,  
 @ToDate DateTime=null,  
 @PerformerName varchar(max)=null  
  
AS  
/*  
FileName: SP_Report_BIL_DoctorReferrals  
CreatedBy/date: Umed/2017-09-04 (YYYY-MM-DD)  
Description: To get the Referral Count of Patient by Doctor wise along with other details  
Remarks:      
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1       Umed/2017-09-04                      created the script  
2       sud/12Dec'17                         altered output columns   
3       Umed/16April-18                     Alter Script (Added OrderBy Date in Desc) 
4		Krishna/9thJun'22					changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
  
BEGIN  
  select  VisitDate,  
         ISNULL(NULLIF(emp.Salutation,'')+'. ','') + emp.FirstName+ISNULL(' '+emp.MiddleName,'')+' '+emp.LastName 'PerformerName',  
      Convert(float,SUM(1)) 'TotalReferrals',  
      Convert(float,SUM( 1/Convert(float,TotalReferrals))) 'ReferralCount',  
         Convert(float,SUM( bttxit.TotalAmount/Convert(float,TotalReferrals))) 'ReferralAmount'  
from BIL_TXN_BillingTransactionItems bttxit,  
       dbo.FN_APPT_GetReferalVisitInformation() vis,  
    EMP_Employee emp  
where   
  bttxit.ServiceDepartmentName='OPD' AND  
  bttxit.RequisitionId = vis.InitialVisitId AND  
  vis.PerformerId=emp.EmployeeId AND  
  VisitDate BETWEEN ISNULL(@FromDate,Convert(date,GETDATE()))  AND ISNULL(@ToDate+1,Convert(date,GETDATE()))  
  AND ISNULL(NULLIF(emp.Salutation,'')+'. ','') + emp.FirstName+ISNULL(' '+emp.MiddleName,'')+' '+emp.LastName LIKE '%'+ISNULL(@PerformerName,'')+'%'  
Group By VisitDate, vis.PerformerId  
     ,ISNULL(NULLIF(emp.Salutation,'')+'. ','') + emp.FirstName+ISNULL(' '+emp.MiddleName,'')+' '+emp.LastName  
Order By VisitDate desc  
END