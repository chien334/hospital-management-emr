CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetCashInvoiceReturnData]
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
-- exec SP_ACC_BIL_GetCashInvoiceReturnData '2023-03-20',3
BEGIN
	SELECT BillReturnItemId AS BillingAccountingSyncId
		,itm.BillReturnItemId 'ReferenceId'
		,'InvoiceReturnItem' AS ReferenceModelName
		,ServiceDepartmentId
		,ServiceItemId AS ItemId
		,itm.PatientId
		,'CashBillReturn' TransactionType
		,'cash' AS PaymentMode
		,itm.RetSubTotal AS SubTotal
		,itm.RetTaxAmount 'TaxAmount'
		,itm.RetDiscountAmount AS DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,CASE 
			WHEN (txn.BillStatus = 'paid')
				THEN itm.RetSubTotal
			WHEN (
					txn.BillStatus = 'unpaid'
					AND ISNULL(txn.ReturnCashAmount, 0) != 0
					)
				THEN (txn.ReturnCashAmount / txn.TotalAmount) * itm.RetTotalAmount --Since we do not have ItemLevel CoPayment we have break it down into Percent and then Amount, Sud/Krishna, 22Feb'23
			END AS 'TotalAmount'
		--,itm.RetTotalAmount AS TotalAmount
		,0 AS IsTransferedToAcc
		,txn.CreatedOn 'TransactionDate'
		,GetDate() 'CreatedOn'
		,txn.CreatedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,NULL AS CreditOrganizationId
		,(
			SELECT dbo.FN_ACC_GetIncomeLedgerId(ServiceDepartmentId, ServiceItemId, @HospitalId)
			) LedgerId
		,(SELECT dbo.[FN_ACC_GetIncomeSubLedgerId](ServiceDepartmentId, ServiceItemId, @HospitalId)) SubLedgerId
	FROM BIL_TXN_InvoiceReturnItems itm
		,BIL_TXN_InvoiceReturn txn
	WHERE txn.BillReturnId = itm.BillReturnId
		AND Convert(DATE, txn.CreatedOn) = @TransactionDate
		--and  ( txn.PaymentMode='cash' OR txn.PaymentMode='card' OR txn.PaymentMode='cheque' OR (txn.PaymentMode ='credit'and itm.BillStatus='paid'))  ---we considering all payment mode as cash , except credit
		AND (
			txn.BillStatus = 'paid'
			OR (
				txn.BillStatus = 'unpaid'
				AND ISNULL(txn.ReturnCashAmount, 0) != 0
				)
			)
		--Sud/Krishna, 22Feb'23, We have added a condition for unpaid BillStatus as well to get CoPayment Cash as well
		AND ISNULL(itm.IsCashBillSyncToAcc, 0) = 0 -- Include only Not-Synced Data for CashBill Return Case--	
END