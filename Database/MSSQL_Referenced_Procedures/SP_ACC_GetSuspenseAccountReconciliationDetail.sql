CREATE PROCEDURE SP_ACC_GetSuspenseAccountReconciliationDetail 
	 @SuspenseAccountLedgerId INT
	,@BankLedgerId INT
AS
/*
--Change History
S.N.          Author/Date                 Description
1.            DevN/30th,June'23           Initial draft to get Suspense A/C Reconciliation Detail.
*/
BEGIN
	SELECT VoucherNumber AS VoucherNumber
		,PartyLedgerId AS LedgerId
		,PartySubLedgerId AS SubLedgerId
		,CASE WHEN DrCr = 1 THEN 0
			ELSE 1 END AS DrCr
		,BankBalance AS Amount
	FROM ACC_TXN_Bank_Reconciliation reconcile
	LEFT JOIN ACC_MAP_BankAndSuspenseAccountReconciliation map ON reconcile.VoucherNumber = map.BankReconciliationVoucherNumber
	WHERE map.BankAndSuspenseAccountReconciliationId IS NULL 
	AND reconcile.PartyLedgerId = @SuspenseAccountLedgerId 
	AND LedgerId = @BankLedgerId
END