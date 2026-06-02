CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetDepositReturnData] 
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
-- exec SP_ACC_BIL_GetDepositReturnData '2023-03-20',3
BEGIN
	SELECT DepositId AS BillingAccountingSyncId
		,DepositId 'ReferenceId'
		,'Deposit' AS ReferenceModelName
		,0 AS ServiceDepartmentId
		,0 AS ItemId
		,PatientId
		,'DepositReturn' TransactionType
		,
		--	 PaymentMode As PaymentMode, --NBB: 16Jul20-card payment not handle yet
		'cash' AS PaymentMode
		,0 AS SubTotal
		,0 AS 'TaxAmount'
		,0 AS DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,OutAmount AS TotalAmount
		,0 AS IsTransferedToAcc
		,CreatedOn 'TransactionDate'
		,GetDate() 'CreatedOn'
		,CreatedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,0 AS CreditOrganizationId
		,0 AS LedgerId
		,0 AS SubLedgerId
	FROM BIL_TXN_Deposit
	WHERE Convert(DATE, CreatedOn) = @TransactionDate
		AND TransactionType = 'ReturnDeposit'
		AND ISNULL(IsDepositSync, 0) = 0 -- Include only Not-Synced Data
END