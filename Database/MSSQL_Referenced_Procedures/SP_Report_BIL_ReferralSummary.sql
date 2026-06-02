--Altering SP_Report_BIL_ReferralSummary SP
--changed ReferredBy to PrescriberId and ReferrerName to PresriberName
-- =============================================  
-- Author/Date:  Sud/Pratik/13Oct'19  
-- Description:  to show referral summary  
-- Remarks:         External or internal can be filtered by IsExternal Flag  
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BIL_ReferralSummary]     ----EXEC [SP_Report_BIL_ReferralSummary]   '2019-08-01','2019-10-01'  
 @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL,  
 @IsExternal bit=null  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date     Remarks  
1.  Sud/Pratik/13Oct'19        Initial Draft  
2.      Dev/24th_Jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
3.	Krishna/9thJun'22		changed ReferredBy to PrescriberId and ReferrerName to PresriberName
4.	Krishna/14thNov'22		  ReferredDoctorName changed to Doctor
*/  
BEGIN  
    
  
SELECT  
        ISNULL(PrescriberId, 0) 'PrescriberId',  
        CASE WHEN ISNULL(PrescriberId, 0) != 0 THEN Doctor ELSE 'Unassigned' END AS 'PrescriberName',  
  --IsExtReferrer,  
  ISNULL(emp.IsExternal,0) AS 'IsExtReferrer',  
        SUM(ISNULL(SubTotal, 0)) 'SubTotal',  
        SUM(ISNULL(DiscountAmount, 0)) AS 'Discount',  
        SUM(ISNULL(ReturnTotalAmount, 0)) AS 'Refund',  
        SUM(ISNULL(TotalAmount, 0) - ISNULL(ReturnTotalAmount, 0)) AS 'NetTotal',  
  
   SUM(ISNULL(CreditAmount, 0)) AS 'CreditAmount',  
   SUM(ISNULL(CreditReceived, 0)) AS 'CreditReceivedAmount'  
  
    FROM FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(@FromDate, @ToDate) itm  
 LEFT JOIN EMP_Employee emp  
 on itm.PrescriberId = emp.EmployeeId  
  
 WHERE ISNULL(emp.IsExternal,0) = ISNULL(@IsExternal, ISNULL(emp.IsExternal,0))  --Take all records if InputParameter is null.  
  
 GROUP BY   
  PrescriberId,  
  Doctor,  
  ISNULL(emp.IsExternal,0)   
 ORDER BY 2  
  
  
 SELECT   
  SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) 'ProvisionalAmount',  
  SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) 'CancelledAmount',  
  SUM(CASE WHEN BillStatus='credit' THEN CreditAmount ELSE 0 END) 'CreditAmount',  
  --sud:7Feb'18--Added CreditReceivedAmount with below condition--  
  SUM(CASE WHEN BillStatus='paid' AND PaymentMode='credit' AND PaidDate is not null and CreditDate is null THEN PaidAmount ELSE 0 END) 'CreditReceivedAmount',  
  --sud:7Feb'18: Added CreditReturnAmount <Needs Revision>  
  SUM(CASE WHEN BillStatus='return' AND PaymentMode='credit' AND PaidDate IS NULL THEN ReturnAmount ELSE 0 END) 'CreditReturnAmount',  
  (SELECT SUM(ISNULL(AdvanceReceived,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceReceived',  
  (SELECT SUM(ISNULL(AdvanceSettled,0)) FROM FN_BIL_GetDepositNProvisionalBetnDateRange(@FromDate,@ToDate)) 'AdvanceSettled'  
FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DoctorSummary(@FromDate, @ToDate)  
END