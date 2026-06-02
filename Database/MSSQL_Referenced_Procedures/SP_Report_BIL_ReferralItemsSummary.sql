--Altering SP_Report_BIL_ReferralItemsSummary SP
--changed ReferredBy to PrescriberId
-- =============================================  
-- Author/Date:  Sud/Pratik/16Oct'19  
-- Description:  to show referral Item summary, We're taking details of all items of given referrerId in a date range.  
-- Remarks:          
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BIL_ReferralItemsSummary]   
@FromDate datetime = NULL,  
@ToDate datetime = NULL,  
@PrescriberId int = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date          Remarks  
1    Sud/Pratik/13Oct'19      initail draft  
2	 Krishna/9thJun'22		  changed ReferredBy to PrescriberId 
3	 Krishna/14thNov'22		  ReferredDoctorName changed to Doctor
*/  
BEGIN  
   SELECT  
       BillingDate 'Date',  
       ISNULL(fnItems.Doctor, 'No Doctor') AS 'PrescriberName',  
       pat.PatientCode,  
       pat.FirstName + ' ' + ISNULL(pat.MiddleName + ' ', '') + pat.LastName 'PatientName',  
      [dbo].[FN_BIL_GetSrvDeptReportingName_DoctorSummary] (fnItems.ServiceDepartmentName, ItemName) AS 'ServiceDepartmentName',  
       fnItems.ItemName,  
       fnItems.Price,  
       ISNULL(fnItems.Quantity, 0) - ISNULL(fnItems.ReturnQuantity, 0) Quantity,  
       fnItems.SubTotal,  
       fnItems.DiscountAmount,  
       fnItems.TotalAmount,  
       fnItems.ReturnTotalAmount 'ReturnAmount',  
       fnItems.TotalAmount - fnItems.ReturnTotalAmount 'NetAmount'  
   FROM   
   
     FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(@FromDate, @ToDate) fnItems  
  
   JOIN PAT_Patient pat ON fnItems.PatientId = pat.PatientId  
   WHERE   
         ISNULL(fnItems.PrescriberId, 0) = @PrescriberId  
    and fnItems.BillingType !='CreditReceived'  
   ORDER BY 1 DESC  
  
  
   SELECT   
    SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) 'ProvisionalAmount',  
    SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) 'CancelledAmount',  
    SUM(CASE WHEN BillStatus='credit' THEN CreditAmount ELSE 0 END) 'CreditAmount'  
   FROM FN_BIL_GetTxnItemsInfoWithDateSeparation_DoctorSummary(@FromDate,@ToDate)  
   WHERE  ISNULL(PrescriberId,0) = @PrescriberId  
  
  
END  --End of SP