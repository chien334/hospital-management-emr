--Altering SP_Report_BIL_DailyMISDrPatientCount SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DailyMISDrPatientCount] -- SP_Report_BIL_DailyMISDrPatientCount '2018-07-27','2018-07-27'  
@FromDate DATETIME = NULL,  
@ToDate DATETIME = NULL  
AS  
/*  
FileName: SP_Report_BILL_DailyMISReport  
Change History  
S.No.    UpdatedBy/Date  Remarks  
1       Ramavtar/2018-08-30     created the script  
2		Krishna/2022-06-08		changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
 SELECT  
  ISNULL(PerformerId,0) 'PerformerId',  
  ISNULL(emp.FirstName + ' ' + emp.LastName,'NoDoctor') 'PerformerName',  
  COUNT(DISTINCT PatientId) 'PatientCount'   
 FROM [FN_BIL_GetTxnItemsInfoWithDateSeparation](@FromDate,@ToDate) bil  
 LEFT JOIN EMP_Employee emp ON bil.PerformerId = emp.EmployeeId  
 GROUP BY bil.PerformerId,emp.FirstName,emp.LastName  
 ORDER BY 2  
END