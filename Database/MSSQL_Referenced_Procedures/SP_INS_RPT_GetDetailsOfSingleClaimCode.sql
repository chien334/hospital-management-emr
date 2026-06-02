CREATE PROCEDURE  [dbo].[SP_INS_RPT_GetDetailsOfSingleClaimCode]
    @PatientId int = NULL,
    @ClaimCode bigint = NULL
AS

/*
 FileName: [SP_INS_RPT_GetDetailsOfSingleClaimCode] 
 Created: 28 Oct'21/Swapnil
 Description: To get Details Of Single Claim Code with PatientId and Claim Code.
 Change History
 S.No.    Date/User                         Change Remarks
 1.       06Oct'21/Swapnil                  inital draft
 2.       Sud/Sanjit: 31-Oct'21             Corrected Pharmacy Data
 3.       Sud/18Jan'21                      Added InvoiceNumber in Billing and Pharmacy Details
										    Added With(NOLOCK) for Uncommitted Read (performance improvement)
 4.       Sud/03Feb'21                      Added InvoiceDate, Price, MRP, 
                                            Removed Grouping since it's no longer required
*/

BEGIN
   


Select top(1) adm.AdmissionDate, adm.DischargeDate, adm.AdmissionStatus
  from PAT_PatientVisits vis WITH(NOLOCK)
     inner join ADT_PatientAdmission adm  WITH(NOLOCK)
  on vis.PatientVisitId=adm.PatientVisitId
  where vis.PatientId=@PatientId
      and vis.VisitType='inpatient'
      and vis.ClaimCode=@ClaimCode


Select 
		txn.PatientId,
		txn.ClaimCode,
		txn.InvoiceNo,
		Convert(Date,txn.CreatedOn) 'InvoiceDate',
		txnItm.ServiceDepartmentName,
		txnItm.ItemId,
		txnItm.ItemName,
		txnItm.Price,
		ISNULL(txnItm.Quantity,0) 'Sales_Quantity',
		ISNULL(txnItm.SubTotal,0) 'Sales_SubTotal',
		ISNULL(txnitm.DiscountAmount,0) 'Sales_Discount',
		ISNULL(txnItm.TotalAmount,0) 'Sales_TotalAmount',
		ISNULL(retItm.RetQty,0) 'Ret_Quantity',
		ISNULL(retItm.RetSubtotal,0) 'Ret_Subtotal',
		ISNULL(retitm.RetDiscountAmount,0) 'Ret_Discount',
		ISNULL(retItm.RetTotalAmount,0) 'Ret_TotalAmount',
		txnitm.TotalAmount - ISNULL(retItm.RetTotalAmount,0) 'Net_TotalAmount'

		from BIL_TXN_BillingTransaction txn  WITH(NOLOCK)
		   INNER JOIN BIL_TXN_BillingTransactionItems txnItm  WITH(NOLOCK)
		       ON txn.BillingTransactionId=txnItm.BillingTransactionId
		LEFT JOIN 
			(Select BillingTransactionItemId, PatientId, 
			 Sum(ISNULL(RetQuantity,0)) 'RetQty',
			 Sum(ISNULL(RetSubTotal,0)) 'RetSubtotal',
			 Sum(ISNULL(RetDiscountAmount,0)) 'RetDiscountAmount',
			 Sum(ISNULL(RetTotalAmount,0)) 'RetTotalAmount'
			 from BIL_TXN_InvoiceReturnItems  WITH(NOLOCK)
			 Where PatientId=@PatientId 
			 Group by BillingTransactionItemId, PatientId
		 ) retItm 		ON txnItm.BillingTransactionItemId=retItm.BillingTransactionItemId

		Where txn.IsInsuranceBilling=1 
		     and txn.PatientId=@patientid
			 and txn.ClaimCode=@ClaimCode

 Select
	  inv.PatientId,
	  inv.ClaimCode,
	  inv.InvoicePrintId 'InvoiceNo',
	  Convert(Date, inv.CreateOn) 'InvoiceDate',
	  invItm.ItemName, gen.GenericName,
	  invItm.ItemId,  invItm.BatchNo, invItm.ExpiryDate, 
	  invItm.MRP,
	  invItm.Quantity 'SalesQuantity',
	  invItm.SubTotal,
	  invItm.TotalAmount 'SalesAmount',
	  ISNULL(invRt.Ret_Quantity,0) 'Ret_Quantity',
	  ISNULL(invRt.Ret_TotalAmount,0)as ReturnAmount, 
	  ISNULL(invItm.TotalAmount,0) - ISNULL(invRt.Ret_TotalAmount,0) AS NetAmount  -- Subtract Return amount here..
  
  from
     PHRM_MST_Store store INNER JOIN 
     PHRM_TXN_Invoice inv  WITH(NOLOCK) on inv.StoreId=store.StoreId
     inner join PHRM_TXN_InvoiceItems invItm  WITH(NOLOCK)  on inv.InvoiceId=invItm.InvoiceId
     inner join PHRM_MST_Item itm on invItm.ItemId=itm.ItemId
     left join PHRM_MST_Generic gen on itm.GenericId = gen.GenericId
	 left join (
	                  Select InvoiceItemId, 
					   SUM(ISNULL(retItm.ReturnedQty,0)) Ret_Quantity, 
					   SUM(ISNULL(retItm.SubTotal,0)) Ret_Subtotal,  
					   SUM(ISNULL(retItm.DiscountAmount,0)) Ret_DiscountAmt, 
					   SUM(ISNULL(retItm.TotalAmount,0)) Ret_TotalAmount
					from PHRM_TXN_InvoiceReturnItems retItm  WITH(NOLOCK)
					     INNER JOIN PHRM_TXN_InvoiceReturn ret  WITH(NOLOCK)
					     ON retItm.InvoiceReturnId = ret.InvoiceReturnId
					Where ret.PatientId=@PatientId
					Group by InvoiceItemId
			    ) invRt 
				on invItm.InvoiceItemId = invRt.InvoiceItemId  

  where 
  store.SubCategory='insurance'  -- take only invoices created from Insurance Dispensaries. 
        AND  inv.PatientId=@PatientId and inv.ClaimCode = @ClaimCode
END