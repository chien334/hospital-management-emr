CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetCashInvoiceData]
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.

*/
-- exec SP_ACC_BIL_GetCashInvoiceData '2023-03-20',3
BEGIN
	SELECT BillingTransactionItemId AS BillingAccountingSyncId
		,BillingTransactionItemId 'ReferenceId'
		,'BillingTransactionItem' AS ReferenceModelName
		,ServiceDepartmentId
		,ServiceItemId AS ItemId
		,itm.PatientId
		,'CashBill' TransactionType
		,'cash' AS PaymentMode
		,itm.SubTotal
		,Tax 'TaxAmount'
		,itm.DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,itm.SubTotal AS TotalAmount
		,0 AS IsTransferedToAcc
		,itm.PaidDate 'TransactionDate'
		,GetDate() 'CreatedOn'
		,itm.PaymentReceivedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,ISNULL(txn.OrganizationId, 0) AS CreditOrganizationId
		,(
			SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId)
			) LedgerId
		,(SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId)) SubLedgerId
	FROM BIL_TXN_BillingTransactionItems itm
		,BIL_TXN_BillingTransaction txn
	WHERE txn.BillingTransactionId = itm.BillingTransactionId
		AND Convert(DATE, itm.PaidDate) = @TransactionDate
		AND itm.BillingTransactionId IS NOT NULL
		AND (
			txn.PaymentMode = 'cash'
			OR txn.PaymentMode = 'card'
			OR txn.PaymentMode = 'cheque'
			)
		AND ISNULL(itm.IsCashBillSync, 0) = 0 -- Include only Not-Synced Data for CashBill Case--
END