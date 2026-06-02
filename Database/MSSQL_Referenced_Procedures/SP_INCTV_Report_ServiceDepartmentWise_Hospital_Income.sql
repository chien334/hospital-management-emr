CREATE PROCEDURE [dbo].[SP_INCTV_Report_ServiceDepartmentWise_Hospital_Income] 
 @FromDate date = NULL,    
 @ToDate date = NULL,    
 @ServiceDepartmentId int = NULL    
AS    
/*    
Author: Krishna,8th,July'22 
Description: To get Incentive reports at items level for servide department.    
Change History-----    
S.No. Date/Author				Remarks    
1.   Krishna,8th,July'22		Initial Draft   
2.	 Krisihna,22ndSept'23		Read PriceCategory

*/    
BEGIN    
 SELECT emp.FullName IncentiveReceiverName,  
  incItm.TransactionDate,   
  incItm.InvoiceNoFormatted,   
  incItm.IncentiveType 'IncomeType',   
  incItm.PatientId,   
  pat.FirstName+' '+pat.LastName 'PatientName',  
  pat.PatientCode 'HospitalNum',   
  incItm.ItemName,  
   txnitm.SubTotal,
 txnitm.DiscountAmount,
 incItm.TotalBillAmount 'TotalAmount',   
 incItm.IncentiveAmount,       
  --Here TDS Percent is hard-coded, we need to add them to Fractionitem table and calculate from there, not from here--sud: 12Feb'20    
  incItm.TDSAmount 'TDSAmount',   
  incItm.IncentiveAmount - incItm.TDSAmount 'NetPayableAmt',   
  incItm.InctvTxnItemId,  
  incItm.IsPaymentProcessed,
  priceCat.PriceCategoryId,
  priceCat.PriceCategoryName  
    
 FROM INCTV_TXN_IncentiveFractionItem incItm    
 INNER JOIN PAT_Patient pat    
 ON incItm.PatientId=pat.PatientId    
 INNER JOIN EMP_Employee emp    
 ON incItm.IncentiveReceiverId=emp.EmployeeId    
 INNER JOIN BIL_TXN_BillingTransactionItems txnitm    
 ON incItm.BillingTransactionItemId = txnitm.BillingTransactionItemId  
 INNER JOIN BIL_CFG_PriceCategory priceCat ON txnitm.PriceCategoryId = priceCat.PriceCategoryId
    
 WHERE    
  ServiceDepartmentId = @ServiceDepartmentId    
  AND Isnull(incItm.IsActive,0)=1    
  AND Convert(Date,incItm.TransactionDate) BETWEEN @FromDate AND @ToDate    
 END