CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetCreditInvoiceReturnData]
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
--exec SP_ACC_BIL_GetCreditInvoiceReturnData '2023-01-10',3
BEGIN
	SELECT itm.BillReturnItemId AS BillingAccountingSyncId
		,BillReturnItemId 'ReferenceId'
		,'InvoiceReturnItem' AS ReferenceModelName
		,ServiceDepartmentId
		,ServiceItemId AS 'ItemId'
		,itm.PatientId
		,'CreditBillReturn' TransactionType
		,txn.PaymentMode AS PaymentMode
		,itm.RetSubTotal AS SubTotal
		,itm.RetTaxAmount 'TaxAmount'
		,itm.RetDiscountAmount AS DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,itm.RetSubTotal AS TotalAmount
		,0 AS IsTransferedToAcc
		,txn.CreatedOn 'TransactionDate'
		,GetDate() 'CreatedOn'
		,txn.CreatedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,bilTxn.OrganizationId AS CreditOrganizationId
		,(
			SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId)
			) LedgerId
		,(SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId)) SubLedgerId
	FROM BIL_TXN_InvoiceReturnItems itm
		,BIL_TXN_InvoiceReturn txn
		,BIL_TXN_BillingTransaction bilTxn
	WHERE txn.BillReturnId = itm.BillReturnId
		AND txn.BillingTransactionId = bilTxn.BillingTransactionId
		AND Convert(DATE, txn.CreatedOn) = @TransactionDate
		AND itm.BillStatus = 'unpaid' --and txn.PaymentMode='credit' w
		AND ISNULL(itm.IsCreditBillSyncToAcc, 0) = 0 -- Include only Not-Synced Data for Credit Return Case--
END