CREATE   PROCEDURE [dbo].[SP_Acc_RPT_GetSystemAduitReport] 
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@voucherReportType VARCHAR(50) = NULL
	,@SectionId INT = NULL
AS
/*
FileName: [SP_ACC_RPT_GetSystemAduitReport]
CreatedBy/date:
Description: 
Change History
S.No.    UpdatedBy/Date              Remarks
1       Vikas/24 June 2020           Get report for system log records of edit voucher, reversal transaction, back date entry for accounting.
2		NageshBB/ 19Aug 2020	     added sectionId check for all records
3       Dev Narayan 26'March'23      Added IsVerified filter in ACC_Transactions table.
*/
BEGIN
	IF (@FromDate IS NOT NULL)
		OR (@ToDate IS NOT NULL)
	BEGIN
		IF (@voucherReportType = 'EditVoucher')
		BEGIN
			-- START: Edit Voucher Logs Details
			SELECT fs.FiscalYearName
				,lg.SectionId
				,sc.SectionName
				,lg.TransactionDate
				,lg.VoucherNumber
				,lg.Reason
				,lg.CreatedOn
				,lg.CreatedBy
				,lg.LogId
				,usr.FullName
			FROM ACC_Log_EditVoucher lg
			LEFT JOIN ACC_MST_FiscalYears fs ON lg.FiscalYearId = fs.FiscalYearId
			LEFT JOIN ACC_MST_SectionList sc ON lg.SectionId = sc.SectionId
			LEFT JOIN EMP_Employee usr ON lg.CreatedBy = usr.EmployeeId
			WHERE CONVERT(DATE, lg.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
				AND lg.SectionId = @SectionId
				-- END: Edit Voucher Logs Details
		END
		ELSE IF (@voucherReportType = 'VoucherReversal')
		BEGIN
			-- START: Reversal voucher txn Logs Details
			SELECT accR.ReverseTransactionId
				,fs.FiscalYearName
				,sc.SectionName
				,accR.TransactionDate
				,accR.Reason
				,accR.CreatedOn
				,accR.CreatedBy
				,usr.FullName
			FROM ACC_ReverseTransaction accR
			LEFT JOIN ACC_MST_FiscalYears fs ON accR.FiscalYearId = fs.FiscalYearId
			LEFT JOIN ACC_MST_SectionList sc ON accR.Section = sc.SectionId
			LEFT JOIN EMP_Employee usr ON accR.CreatedBy = usr.EmployeeId
			WHERE CONVERT(DATE, accR.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
				AND accR.Section = @SectionId
				-- END: Reversal voucher txn Logs Details
		END
		ELSE IF (@voucherReportType = 'BackDateEntry')
		BEGIN
			-- START: Back Date Entry txn Logs Details
			SELECT txn.TransactionId
				,txn.SectionId
				,sc.SectionName
				,txn.TransactionDate
				,txn.VoucherNumber
				,txn.CreatedOn
				,txn.CreatedBy
				,usr.FullName
			FROM ACC_Transactions txn
			LEFT JOIN ACC_MST_SectionList sc ON txn.SectionId = sc.SectionId
			LEFT JOIN EMP_Employee usr ON txn.CreatedBy = usr.EmployeeId
			WHERE CONVERT(DATE, txn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
				AND txn.SectionId = @SectionId
				AND txn.IsVerified = 1
				-- END: Back Date Entry txn Logs Details
		END
	END
END