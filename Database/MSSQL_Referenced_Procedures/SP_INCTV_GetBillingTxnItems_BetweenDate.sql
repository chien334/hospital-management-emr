CREATE PROCEDURE [dbo].[SP_INCTV_GetBillingTxnItems_BetweenDate]   -- EXEC SP_INCTV_GetBillingTxnItems_BetweenDate '2020-04-01', '2020-04-10'
	( @FromDate DATETIME = NULL,
      @ToDate DATETIME = NULL)
AS
/*
 File: SP_INCTV_GetBillingTxnItems_BetweenDate
 Description:  To get billing transaction items for fraction,
 Conditions/Checks: 
   1. Returned Items are removed.
   2. Joining with EMployee Table twice for Assigned and ReferredBy Employee
   3. FractionCount (number) is the count of FractionItem  in Incentive_FractionItem table for BillingTransactionItemId
        
 Remarks: This can later be extended and used in Billing -> Edit Doctor as well since the fields are preety much similar.
 Change History:
 S.No.    ChangeDate/By					Remarks
 1.      10Apr'20/Sud					Initial Draft 
 2.      11June2020/Pratik				GroupDistribution Impacts on Existing Functionalities 
 3.		 22ndSept'23/Krishna					Read PriceCategory 
*/
BEGIN

select
     pat.PatientId, 
	 pat.ShortName 'PatientName', 
	 pat.PatientCode,
	 fyear.FiscalYearFormatted +'-'+bilTxn.InvoiceCode + cast(bilTxn.InvoiceNo as varchar(20))AS 'InvoiceNo', 
	 bilTxn.CreatedOn 'TransactionDate',  
	 biltxn.BillingTransactionId, 
	 txnItm.BillingTransactionItemId 'BillingTransactionItemId', 
	 txnItm.ServiceDepartmentName, 
	 txnItm.ItemName,
	 txnItm.ItemId,
	 txnItm.Quantity , 
	 txnItm.TotalAmount,
	 txnItm.PerformerName 'AssignedToEmpName', 
	 emp2.FullName 'ReferredByEmpName', 
	 inctvTxnItm.FrcCount 'FractionCount',
	 priceCat.PriceCategoryName,
	 priceCat.PriceCategoryId
from  BIL_CFG_FiscalYears fyear, 
	PAT_Patient pat,
    BIL_TXN_BillingTransaction bilTxn 
	     JOIN BIL_TXN_BillingTransactionItems txnItm
	ON bilTxn.BillingTransactionId = txnItm.BillingTransactionId
	INNER JOIN BIL_CFG_PriceCategory priceCat ON txnItm.PriceCategoryId = priceCat.PriceCategoryId
	    --LEFT JOIN EMP_Employee emp1 
		   --ON txnItm.ProviderId = emp1.EmployeeId  -- for AssignedToDoctor
        LEFT JOIN EMP_Employee emp2
		   ON txnItm.PrescriberId= emp2.EmployeeId
    LEFT JOIN (Select BillingTransactionItemId, Count(*) 'FrcCount'  from INCTV_TXN_IncentiveFractionItem where IsActive=1 Group By BillingTransactionItemId ) inctvTxnItm
	    ON txnItm.BillingTransactionItemId = inctvTxnItm.BillingTransactionItemId

WHERE 
	    bilTxn.FiscalYearId = fyear.FiscalYearId 
	AND bilTxn.PatientId=pat.PatientId
	AND Convert(Date,bilTxn.CreatedOn) Between @FromDate AND @ToDate
	AND ISNULL(bilTxn.ReturnStatus,0) = 0
 
END