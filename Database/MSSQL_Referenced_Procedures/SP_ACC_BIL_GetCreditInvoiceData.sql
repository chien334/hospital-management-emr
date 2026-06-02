CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetCreditInvoiceData] 
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
-- exec SP_ACC_BIL_GetCreditInvoiceData '2023-05-07',1
BEGIN
	SELECT BillingTransactionItemId AS BillingAccountingSyncId
		,BillingTransactionItemId 'ReferenceId'
		,'BillingTransactionItem' AS ReferenceModelName
		,ServiceDepartmentId
		,ServiceItemId AS 'ItemId'
		,itm.PatientId
		,'CreditBill' TransactionType
		,txn.PaymentMode AS PaymentMode
		,itm.SubTotal
		,Tax 'TaxAmount'
		,itm.DiscountAmount
		,ISNULL(itm.CoPaymentCashAmount, 0) AS 'CoPaymentCashAmount'
		,itm.SubTotal AS TotalAmount
		,0 AS IsTransferedToAcc
		,txn.CreatedOn 'TransactionDate'
		,-- this is credit date.. 
		GetDate() 'CreatedOn'
		,itm.CreatedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,txn.OrganizationId AS CreditOrganizationId
		,(
			SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId)
			) LedgerId
		,(SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId)) SubLedgerId
	FROM BIL_TXN_BillingTransactionItems itm
		,BIL_TXN_BillingTransaction txn
	WHERE txn.BillingTransactionId = itm.BillingTransactionId
		AND Convert(DATE, txn.CreatedOn) = @TransactionDate --changed: sud-10Aug'20--Corrected to TransactionCreatedOn from ItemCreatedOn
		AND itm.BillingTransactionId IS NOT NULL
		AND txn.PaymentMode = 'credit'
		AND ISNULL(itm.IsCreditBillSync, 0) = 0 -- Include only Not-Synced Data for CreditBill Case--
END