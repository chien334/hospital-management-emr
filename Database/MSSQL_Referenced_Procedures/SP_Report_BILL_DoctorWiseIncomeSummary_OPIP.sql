--Altering SP_Report_BILL_DoctorWiseIncomeSummary_OPIP SP
--changed ProviderId to PerformerId and ProviderName to PerformerName 
-- =============================================  
-- Author/Date:  Sud/08Aug2018  
-- Description:  to show DoctorWise IncomeSummary (Inpatient + Outpatient)  
-- Remarks: We're taking AssignedTo Field Only in BillingTransactionItem table.   
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BILL_DoctorWiseIncomeSummary_OPIP]  
 @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL,  
 @PerformerId INT = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date     Remarks  
1  Sud/08Aug'18   created the script  
2  Ramavtar/08Aug'18  getting doctor name from employee table  
3.      sud/22Aug'18            updated for IP Records  
4.      Dev/24th_Jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
5.	Krishna/9thJun'22			changed ProviderId to PerformerId and ProviderName to PerformerName
*/  
BEGIN  
  
SELECT  
  ISNULL(OPD.PerformerName, IPD.PerformerName) 'DoctorName',  
  ISNULL(OPD.SubTotal, 0) 'OP_Collection',  
  ISNULL(OPD.Discount, 0) 'OP_Discount',  
  ISNULL(OPD.Refund, 0) 'OP_Refund',  
  ISNULL(OPD.NetTotal, 0) 'OP_NetTotal',  
  ISNULL(IPD.SubTotal, 0) 'IP_Collection',  
  ISNULL(IPD.Discount, 0) 'IP_Discount',  
  ISNULL(IPD.Refund, 0) 'IP_Refund',  
  ISNULL(IPD.NetTotal, 0) 'IP_NetTotal',  
  ISNULL(OPD.NetTotal, 0) + ISNULL(IPD.NetTotal, 0) 'Grand_Total'  
FROM (SELECT  
  CASE  
   WHEN PerformerId IS NOT NULL THEN PerformerName  
   ELSE 'Unassigned'  
  END AS 'PerformerName',  
  SUM(ISNULL(SubTotal, 0)) 'SubTotal',  
  SUM(ISNULL(DiscountAmount, 0)) AS 'Discount',  
  SUM(ISNULL(ReturnAmount, 0)) AS 'Refund',  
  SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnAmount, 0)) AS 'NetTotal'  
 FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(@FromDate, @ToDate)  
 WHERE BillingType = 'OutPatient' AND BillStatus != 'cancelled'  
  AND (ISNULL(@PerformerId, ISNULL(PerformerId, 0)) = ISNULL(PerformerId, 0))  
 GROUP BY PerformerId,PerformerName) OPD  
FULL OUTER JOIN (  
 SELECT  
  CASE  
   WHEN PerformerId IS NOT NULL THEN PerformerName  
   ELSE 'Unassigned'  
  END AS 'PerformerName',  
  SUM(ISNULL(SubTotal, 0)) 'SubTotal',  
  SUM(ISNULL(DiscountAmount, 0)) AS 'Discount',  
  SUM(ISNULL(ReturnAmount, 0)) AS 'Refund',  
  SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnAmount, 0)) AS 'NetTotal'  
 FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(@FromDate, @ToDate)  
 WHERE BillingType = 'Inpatient' AND BillStatus != 'cancelled'  
  AND (ISNULL(@PerformerId, ISNULL(PerformerId, 0)) = ISNULL(PerformerId, 0))  
 GROUP BY PerformerId,PerformerName) IPD  
ON OPD.PerformerName = IPD.PerformerName  
ORDER BY DoctorName  
  
SELECT   
  SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) 'ProvisionalAmount',  
  SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) 'CancelledAmount',  
  SUM(CASE WHEN BillStatus='credit' THEN CreditAmount ELSE 0 END) 'CreditAmount',  
  (SELECT SUM(ISNULL(AdvanceReceived,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceReceived',  
  (SELECT SUM(ISNULL(AdvanceSettled,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceSettled'  
 FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(@FromDate, @ToDate)  
 WHERE (ISNULL(@PerformerId, ISNULL(PerformerId, 0)) = ISNULL(PerformerId, 0))  
END