CREATE PROCEDURE [dbo].[SP_ACC_BIL_GetDiscountReturnData]	
	@TransactionDate DATE
	,@HospitalId INT
AS
--Change History
/*
SN.                Auther/DateTime                   Description
1.                 DevN/23th March 23                Separated from SP_ACC_Bill_GetBillingDataForAccTransfer
2.                 DevN/19th May 23                  Added SubLedgerId field in select statement.
*/
-- exec SP_ACC_BIL_GetDiscountReturnData '2023-03-20',3
BEGIN
	SELECT settl.SettlementId AS BillingAccountingSyncId
		,settl.SettlementId 'ReferenceId'
		,--- 8th-Feb bikash, we have recorded discount return in Settlement table  
		'DiscountReturn' AS ReferenceModelName
		,0 ServiceDepartmentId
		,0 ItemId
		,settl.PatientId
		,'DiscountReturn' TransactionType
		,settl.PaymentMode
		,0 AS SubTotal
		,0 'TaxAmount'
		,0 AS DiscountAmount
		,0 AS 'CoPaymentCashAmount'
		,settl.DiscountReturnAmount AS TotalAmount
		,0 AS IsTransferedToAcc
		,settl.CreatedOn 'TransactionDate'
		,-- this is discount returned date.. 
		GetDate() 'CreatedOn'
		,settl.CreatedBy AS CreatedBy
		,0 AS SettlementDiscountAmount
		,NULL AS Remark
		,settl.OrganizationId AS CreditOrganizationId
		,0 AS LedgerId
		,0 AS SubLedgerId
	FROM BIL_TXN_Settlements settl
	WHERE Convert(DATE, settl.SettlementDate) = @TransactionDate
		AND ISNULL(settl.DiscountReturnAmount, 0) != 0
		-- AND  ( settl.PaymentMode='cash' OR settl.PaymentMode='card' OR settl.PaymentMode='cheque') 
END