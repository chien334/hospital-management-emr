CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetSettlementData] 
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/20th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
-- exec SP_ACC_BIL_GetSettlementData '2023-03-20',3
BEGIN
	SELECT settl.SettlementId AS BillingAccountingSyncId
		,settl.SettlementId 'ReferenceId'
		,---4th-Feb bikash, now SettlementId taken as referenceId as IsSyncToAcc flag is in Settlement table  
		'CreditBillPaid' AS ReferenceModelName
		,0 ServiceDepartmentId
		,0 ItemId
		,settl.PatientId
		,'CreditBillPaid' TransactionType
		,settl.PaymentMode
		,0 AS SubTotal
		,0 'TaxAmount'
		,0 AS DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,settl.CollectionFromReceivable AS TotalAmount
		,0 AS IsTransferedToAcc
		,settl.CreatedOn 'TransactionDate'
		,-- this is Settlement date.. 
		GetDate() 'CreatedOn'
		,settl.CreatedBy AS CreatedBy
		,ISNULL(settl.DiscountAmount,0) AS SettlementDiscountAmount
		,NULL AS Remark
		,settl.OrganizationId AS CreditOrganizationId
		,0 AS LedgerId
		,0 AS SubLedgerId
	FROM BIL_TXN_Settlements settl
	WHERE Convert(DATE, settl.SettlementDate) = @TransactionDate
		AND ISNULL(settl.DiscountReturnAmount, 0) = 0 -- not including discount return case
		-- AND  ( settl.PaymentMode='cash' OR settl.PaymentMode='card' OR settl.PaymentMode='cheque') 
		AND ISNULL(settl.IsSyncToAcc, 0) = 0 -- Include only Not-Synced Data for CreditBillPaid Case--
END