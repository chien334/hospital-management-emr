CREATE PROCEDURE [dbo].[SP_Report_INCTV_DoctorSummary] --EXEC SP_Report_INCTV_DoctorSummary '2021-07-20','2022-11-22',0 
 @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL,
 @IsRefferalOnly BIT = 0
AS 

/************************************************************************
--Altering SP_Report_INCTV_DoctorSummary SP
--Added a column Pan No. of the respective doctor   
-- Author: Nirmala/18Nov'22 
--Change History:  
S.No.  Author/Date                   Remarks  
1.    Pratik/20Nov'19               Initial Draft  
2.    Sud/26Feb'20                  TDSPercentage added in Summary.  
3.    Pratik/18Mar'20               No need of IncentiveType, TDSPercent, just show the summary at doctor level for given date range.   
4.	  Krishna,9thJun'22				changed ReferrerName to PrescriberName and ReferredId to PrescriberId
5.    23Aug'22/Dev Narayan          Added filter IncentiveType = 'referral' for new Report ->'Incentive Referral Summary'
6.    Nirmala/18Nov'22              Add a column Pan No. of the respective doctor
*************************************************************************/
BEGIN  
SELECT  emp.FullName AS PrescriberName, incItm.IncentiveReceiverId AS PrescriberId  
   ,SUM(incItm.IncentiveAmount) 'DocTotalAmount'  
   ,SUM(incItm.TDSAmount) 'TDSAmount'  
   ,SUM(incItm.IncentiveAmount - incItm.TDSAmount) 'NetPayableAmount' 
   ,emp.PANNumber 'PanNo'
   FROM INCTV_TXN_IncentiveFractionItem incItm    
   INNER JOIN EMP_Employee emp  
   ON incItm.IncentiveReceiverId=emp.EmployeeId  
  
 WHERE   
     Isnull(incItm.IsActive,0)=1  
     AND Convert(Date,incItm.TransactionDate) Between @FromDate AND @ToDate  
	 AND ((@IsRefferalOnly = 1 AND incItm.IncentiveType = 'referral')
		OR (@IsRefferalOnly = 0)
	 )
  
  GROUP BY emp.FullName, incItm.IncentiveReceiverId,PANNumber  
END