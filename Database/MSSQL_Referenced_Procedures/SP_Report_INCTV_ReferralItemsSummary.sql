CREATE PROCEDURE [dbo].[SP_Report_INCTV_ReferralItemsSummary] --EXEC SP_Report_INCTV_ReferralItemsSummary '2022-04-21','2022-04-21',1087  
 @FromDate date = NULL,  
 @ToDate date = NULL,  
 @EmployeeId int = NULL,
 @IsRefferalOnly BIT = 0
AS  
/*  
Author: Pratik/20Nov'19  
Description: To get Incentive reports at items level for input doctor.  
Change History-----  
S.No. Date/Author					Remarks  
1. 20Nov'19/Pratik					Initial Draft  
2. 12Feb'20/Sud						TDS percent hardcoded for temporary purpose, need to revise it soon.  
3. 25Feb'20/Pratik					TDS percentage is calculated from employee profile  
4. 06Aug'21/Aniket					Previous Adjusted Amount is added from INCTV_TXN_PaymentInfo  
5. 24Aug'21/Aniket					Updated query, replaced right join with left join.  
6. 09Nov'21/Pratik					updated query, added return status, subtotal and discount amount of billing items  
7. 22March'22/Krishna				Updated Query to get PreviousAdjustmentAmount of Specific Employee (Receiver)  
8. 27Apr'22/Krishna/Sud				Join with PaymentInfo removed since it's giving multiple records 
									when there are multple payments made in past.  
9. 23Aug'22/Dev Narayan				Added filter IncentiveType = 'referral' for new Report ->'Incentive Referral Summary'
10.22ndSept'23/Krishna				Read PriceCategory
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
		incItm.TotalBillAmount 'TotalAmount', 
		incItm.FinalIncentivePercent, 
		incItm.IncentiveAmount,
		incItm.TDSPercentage 'TDSPercentage',
		incItm.IsReturnTxn ,
		txnitm.SubTotal,txnitm.DiscountAmount,  
		--Here TDS Percent is hard-coded, we need to add them to Fractionitem table and calculate from there, 
		--not from here--sud: 12Feb'20  
		incItm.TDSAmount 'TDSAmount', 
		incItm.IncentiveAmount - incItm.TDSAmount 'NetPayableAmt', 
		incItm.InctvTxnItemId,
		incItm.IsPaymentProcessed,--,incItm.BillingTransactionId, incItm.BillingTransactionItemId  
  ISNULL((SELECT TOP 1 AdjustedAmount   
   FROM INCTV_TXN_PaymentInfo p   
   WHERE p.ReceiverId = @EmployeeId ORDER BY p.CreatedOn DESC),0) 'PreviousAdjustedAmount' ,
   priceCat.PriceCategoryId,
   priceCat.PriceCategoryName
  
 FROM INCTV_TXN_IncentiveFractionItem incItm  
 INNER JOIN PAT_Patient pat  
 ON incItm.PatientId=pat.PatientId  

 INNER JOIN EMP_Employee emp  
 ON incItm.IncentiveReceiverId=emp.EmployeeId  
 -- LEFT JOIN INCTV_TXN_PaymentInfo p  
 --ON incItm.IncentiveReceiverId = p.ReceiverId  
 INNER JOIN BIL_TXN_BillingTransactionItems txnitm  
 ON incItm.BillingTransactionItemId = txnitm.BillingTransactionItemId  
 INNER JOIN BIL_CFG_PriceCategory priceCat ON txnitm.PriceCategoryId = priceCat.PriceCategoryId
  
 WHERE  
  IncentiveReceiverId = @EmployeeId  
  AND Isnull(incItm.IsActive,0)=1  
  AND Convert(Date,incItm.TransactionDate) BETWEEN @FromDate AND @ToDate  
  	 AND ((@IsRefferalOnly = 1 AND incItm.IncentiveType = 'referral')
		OR (@IsRefferalOnly = 0)
	 )
 END