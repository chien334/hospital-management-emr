CREATE Procedure [dbo].[SP_ACC_DailyTransactionReportDetails] 
	@VoucherNumber varchar(50), @HospitalId INT	
AS
/************************************************************************
FileName: [SP_ACC_DailyTransactionReportDetails]
Author  : NageshBB
Created date: 12July2021
Description:			
Change History
S.No.    UpdatedBy/Date                        Remarks
1       NageshBB /12July2021		  updated script for return bill changes
2		Aniket /21Sep2021			  updated script for bill return changes 

*************************************************************************************/

BEGIN
 Declare @TransactionType varchar(max),@ReferenceIds varchar(200)
 SET @TransactionType = (Select STRING_AGG(TransactionType, ',') as 'TrasactionType' 
						 From ACC_Transactions 
						 Where HospitalId= @HospitalId AND	 VoucherNumber = @VoucherNumber )
 
 SET @ReferenceIds =(Select STRING_AGG(ReferenceId, ',') as 'TrasactionType' 
					 From ACC_Transactions txn 
					 JOIN ACC_TXN_Link txnLink on txn.TransactionId= txnLink.TransactionId
					 WHERE  txn.HospitalId= @HospitalId AND txn.VoucherNumber =@VoucherNumber ) 



 IF(('DepositAdd') IN(select * from STRING_SPLIT(@TransactionType, ','))
   OR ('DepositReturn') IN(select * from STRING_SPLIT(@TransactionType, ',')) )
		SELECT 
			pat.FirstName + ' ' + ISNULL(pat.MiddleName,'') + ' ' + pat.LastName  as 'PatientName',
			dep.ReceiptNo as 'ReceiptNo',
			SUM(dep.Amount) as 'TotalAmount',
			dep.PaymentMode as 'PaymentMode'
		FROM BIL_TXN_Deposit dep 	
		join PAT_Patient pat on dep.PatientId = pat.PatientId
		WHERE dep.DepositId in (select * from STRING_SPLIT(@ReferenceIds, ',')) 

		GROUP BY
			pat.FirstName,pat.MiddleName,pat.LastName,
			dep.ReceiptNo ,
			dep.PaymentMode 

 --IF( ('CashBill') IN(select * from STRING_SPLIT(@TransactionType, ','))
	--OR ('CreditBill') IN(select * from STRING_SPLIT(@TransactionType, ','))
	--OR ('CashBillReturn') IN(select * from STRING_SPLIT(@TransactionType, ','))
	--OR ('CreditBillReturn') IN(select * from STRING_SPLIT(@TransactionType, ','))
 --  )
	--	SELECT 
	--			txn.InvoiceCode + cast(txn.InvoiceNo as varchar) as InvoiceNo,
	--			pat.FirstName + ' ' + ISNULL(pat.MiddleName,'') + ' ' + pat.LastName  as 'PatientName',
	--			itm.*
	--	FROM BIL_TXN_BillingTransactionItems itm 
	--			join BIL_TXN_BillingTransaction txn on itm.BillingTransactionId= txn.BillingTransactionId
	--			join PAT_Patient pat on itm.PatientId = pat.PatientId 
	--	WHERE itm.BillingTransactionItemId in (select * from STRING_SPLIT(@ReferenceIds, ','))

 IF( ('CashBill') IN(select * from STRING_SPLIT(@TransactionType, ','))
	OR ('CreditBill') IN(select * from STRING_SPLIT(@TransactionType, ','))
   )
		SELECT 
				txn.InvoiceCode + cast(txn.InvoiceNo as varchar) as InvoiceNo,
				pat.FirstName + ' ' + ISNULL(pat.MiddleName,'') + ' ' + pat.LastName  as 'PatientName',
				itm.*
		FROM BIL_TXN_BillingTransactionItems itm 
				join BIL_TXN_BillingTransaction txn on itm.BillingTransactionId= txn.BillingTransactionId
				join PAT_Patient pat on itm.PatientId = pat.PatientId 
		WHERE itm.BillingTransactionItemId in (select * from STRING_SPLIT(@ReferenceIds, ','))

IF(('CashBillReturn') IN(select * from STRING_SPLIT(@TransactionType, ','))
	OR ('CreditBillReturn') IN(select * from STRING_SPLIT(@TransactionType, ','))
   )
		SELECT 
				retTxn.InvoiceCode + cast(retTxn.CreditNoteNumber as varchar) as InvoiceNo,
				pat.FirstName + ' ' + ISNULL(pat.MiddleName,'') + ' ' + pat.LastName  as 'PatientName',
				retItm.*
		FROM BIL_TXN_InvoiceReturnItems retItm 
				join BIL_TXN_InvoiceReturn retTxn on retItm.BillReturnId= retTxn.BillReturnId
				join PAT_Patient pat on retItm.PatientId = pat.PatientId 
		WHERE retItm.BillReturnItemId  in (select * from STRING_SPLIT(@ReferenceIds, ','))
END