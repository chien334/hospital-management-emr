CREATE PROCEDURE [dbo].[SP_ACC_BankReconcilationDetail]
	@FromDate DATETIME
	,@ToDate DATETIME
	,@LedgerId INT
	,@VoucherTypeId INT
	,@Status INT
AS
/* 
  exec [SP_ACC_BankReconcilationDetail] '2022-11-05','2022-11-15',180,3,1
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 14'Nov'22                   SP Script created for Bank Reconcilation Detail
  2.      Dev Narayan 26'March'23                 Added IsVerified filter in ACC_Transactions table.
  3.      DevN 4th May, 23                        Get SubLedger Information in BRS..
  4.      DevN 25th June,23                       Exclude Reversed Vouchers in BRS.
*/
BEGIN

	--Table 1: Reconcilation Data
	SELECT txn.VoucherNumber
		,txn.SectionId
		,txn.TransactionDate
		,txn.FiscalYearId
		,item.LedgerId AS 'PartyLedgerId'
		,ledger.LedgerName AS 'PartyLedgerName'
		,subLedgerTxn.SubLedgerId AS 'PartySubLedgerId'
		,subLedger.SubLedgerName AS 'PartySubLedgerName'
		,voucher.VoucherName
		,txn.ChequeNumber
		,txn.ChequeDate
		,CASE 
			WHEN ISNULL(item.DrCr, 0) = 0
				THEN item.Amount
			ELSE 0
			END AS 'LedgerCr'
		,CASE 
			WHEN ISNULL(item.DrCr, 0) = 0
				THEN 0
			ELSE item.Amount
			END AS 'LedgerDr'
		,item.DrCr
		,txn.VoucherId AS 'VoucherTypeId'
		,reconsile.BankTransactionDate
		,item.Amount AS 'BankBalance'
		,CASE 
			WHEN reconsile.Id IS NULL
				THEN 'open'
			ELSE 'close'
			END AS 'Status'
		,txn.Remarks AS 'Remark'
		,txn.TransactionId
		,txn.HospitalId
		,reconsile.BankRefNumber
		,reconsile.VoucherTypeId
		,@LedgerId AS LedgerId
		,0 AS IsVerified
	FROM ACC_TransactionItems item
	JOIN ACC_Transactions txn ON item.TransactionId = txn.TransactionId
	JOIN ACC_TXN_SubledgerRecords subLedgerTxn ON item.TransactionItemId = subLedgerTxn.TransactionItemId AND item.LedgerId = subLedgerTxn.LedgerId
	JOIN ACC_Ledger ledger ON item.LedgerId = ledger.LedgerId
	JOIN ACC_MST_SubLedger subLedger ON subLedgerTxn.SubLedgerId = subLedger.SubLedgerId
	JOIN ACC_MST_Vouchers voucher ON txn.VoucherId = voucher.VoucherId
	LEFT JOIN ACC_TXN_Bank_Reconciliation reconsile ON txn.TransactionId = reconsile.TransactionId
		AND item.LedgerId = reconsile.PartyLedgerId
	WHERE CONVERT(DATE, txn.TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
		AND ISNULL(txn.IsVoucherReversed,0) = 0
		AND txn.TransactionId IN (
			SELECT TransactionId
			FROM ACC_TransactionItems
			WHERE LedgerId = @LedgerId
			)
		AND item.LedgerId <> @LedgerId
		AND txn.IsVerified = 1
		AND (
			txn.VoucherId = @VoucherTypeId
			OR @VoucherTypeId = 0
			)
		AND (
			(
				CASE 
					WHEN reconsile.BankTransactionDate IS NULL
						THEN 1
					ELSE 2
					END
				) = @Status
			OR @Status = 0
			)

	--Table 2: Reconcilation Opening Balance
	SELECT ISNULL(SUM(CASE 
					WHEN DrCr = 1
						THEN BankBalance
					ELSE - BankBalance
					END), 0) AS ReconcileOpeningBalance
	FROM ACC_TXN_Bank_Reconciliation
	WHERE LedgerId = @LedgerId
END