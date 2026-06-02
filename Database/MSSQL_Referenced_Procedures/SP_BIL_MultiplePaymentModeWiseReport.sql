CREATE PROCEDURE [dbo].[SP_BIL_MultiplePaymentModeWiseReport] 
		@FromDate DATE, 
		@ToDate DATE,
		@PaymentMode NVARCHAR(20) = NULL,
		@Type NVARCHAR(30) = NULL,
		@User INT = NULL

	/*
	FileName: [SP_BIL_MultiplePaymentModeWiseReport]
	CreatedBy/date: KRISHNA/2022-05-03
	Description: To get the Multiple Payment Mode wise Report (Cash Sales, Deposit Received and Credit Settlement) except for Cash Payment Method
	//Execution Example : EXECUTE SP_BIL_MultiplePaymentModeWiseReport '2021-10-01', '2022-03-01', 'e-sewa', 'cash sales', 1


	Change History
	S.No.    UpdatedBy/Date                        Remarks
	1.		KRISHNA/2022-05-03						initial draft
	2.		KRISHNA/2022-07-25						Added User Filter for Summary
	*/
	AS
	BEGIN
		IF @PaymentMode = 'all'
			BEGIN
			SET @PaymentMode = null;
		END

		IF @Type = 'all'
			BEGIN
			SET @Type = null;
		END
	SELECT *
		FROM (
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'CashSales' THEN 'Cash Sales'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'CashSales' THEN CONCAT (txn.InvoiceCode,'-',txn.InvoiceNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.InAmount, 0) 'NetTotal'
					--,ISNULL(empTxn.OutAmount, 0) 'OutAmount'
					--,ISNULL(empTxn.InAmount, 0) - ISNULL(empTxn.OutAmount,0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_BillingTransaction txn ON txn.BillingTransactionId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = txn.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CashSales'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
	
			UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'Deposit' THEN 'Deposit Received'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'Deposit' THEN CONVERT(VARCHAR(50), dep.ReceiptNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.InAmount, 0) 'NetTotal'
					--,ISNULL(empTxn.OutAmount, 0) 'OutAmount'
					--,ISNULL(empTxn.InAmount, 0) - ISNULL(empTxn.OutAmount,0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_Deposit dep ON dep.DepositId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = dep.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'Deposit'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
	
			UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'CollectionFromReceivable' THEN 'Credit Settlement'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'CollectionFromReceivable' THEN CONCAT ('SR','-',sett.SettlementReceiptNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.InAmount, 0) 'NetTotal'
					--,ISNULL(empTxn.OutAmount, 0) 'OutAmount'
					--,ISNULL(empTxn.InAmount, 0) - ISNULL(empTxn.OutAmount,0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_Settlements sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CollectionFromReceivable'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)

				UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'SalesReturn' THEN 'Cash Sales Return'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'SalesReturn' THEN CONCAT ('CR','-',ret.BillReturnId)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					--,ISNULL(empTxn.InAmount, 0) 'InAmount'
					,ISNULL(empTxn.OutAmount, 0) 'NetTotal'
					--,ISNULL(empTxn.InAmount, 0) - ISNULL(empTxn.OutAmount,0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_InvoiceReturn ret ON ret.BillReturnId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = ret.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'SalesReturn'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
				UNION
				(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'ReturnDeposit' THEN 'Deposit Refund'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'ReturnDeposit' THEN CONVERT(VARCHAR(50), dep.ReceiptNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.OutAmount, 0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_Deposit dep ON dep.DepositId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = dep.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'ReturnDeposit'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
			UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'CashDiscountGiven' THEN 'Cash Discount Given'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'CashDiscountGiven' THEN CONCAT ('SR','-',sett.SettlementReceiptNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.OutAmount, 0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_Settlements sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CashDiscountGiven'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
				UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'CashDiscountReceived' THEN 'Cash Discount Received'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'CashDiscountReceived' THEN CONCAT ('SR','-',sett.SettlementReceiptNo)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.InAmount, 0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN BIL_TXN_Settlements sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CashDiscountReceived'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
				UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'MaternityAllowance' THEN 'Maternity Allowance'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'MaternityAllowance' THEN CONVERT(VARCHAR(50),mat.PatientPaymentId)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.OutAmount, 0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN MAT_TXN_PatientPayments mat ON mat.PatientPaymentId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = mat.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'MaternityAllowance'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
				UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'MaternityAllowanceReturn' THEN 'Maternity Allowance Return'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'MaternityAllowanceReturn' THEN CONVERT(VARCHAR(50),mat.PatientPaymentId)
					 END 'ReceiptNo'
					,pat.PatientCode 'HospitalNo'
					,pat.ShortName 'PatientName'
					,ISNULL(empTxn.InAmount, 0) 'NetTotal'
					,emp.FullName 'User'
					,emp.EmployeeId
					,cntr.CounterName 'Counter'
					,empTxn.Remarks
				FROM TXN_EmpCashTransaction empTxn
						INNER JOIN MAT_TXN_PatientPayments mat ON mat.PatientPaymentId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = mat.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN BIL_CFG_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'MaternityAllowanceReturn'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
			) tbl
		WHERE 
			(@PaymentMode IS NULL OR @PaymentMode = 'null' OR tbl.PaymentMode = @PaymentMode)
			AND (@Type IS NULL OR @Type = 'null' OR tbl.Type = @Type)
			AND (@User IS NULL OR @User = 0 OR tbl.EmployeeId = @User)
		ORDER BY tbl.DATE DESC

		SELECT
			PaymentModes,
			ISNULL(CashSales,0) 'CashSales',
			ISNULL(SalesReturn,0)'ReturnCashSales',
			ISNULL(Deposit,0) 'DepositReceived',
			ISNULL(ReturnDeposit,0)'DepositRefund',
			(ISNULL(CashDiscountGiven,0) - ISNULL(CashDiscountReceived,0))'SettlementDiscount',
			ISNULL(MaternityAllowance,0) - ISNULL(MaternityAllowanceReturn,0) 'OtherPaymentsGiven',
			ISNULL(CollectionFromReceivable,0) 'CollectionFromReceivable',

			--Calculation for Cash Collection--
			ISNULL(CashSales,0) - ISNULL(SalesReturn,0)
			+ ISNULL(Deposit,0) - ISNULL(ReturnDeposit,0)
			+ ISNULL(CollectionFromReceivable,0)
			- (ISNULL(CashDiscountGiven,0) - ISNULL(CashDiscountReceived,0))
			- (ISNULL(MaternityAllowance,0) - ISNULL(MaternityAllowanceReturn,0))
			AS 'CashCollection'
		FROM   
			(SELECT 
					empTxn.TransactionType,
					pModes.PaymentSubCategoryName 'PaymentModes',
					CASE 
						WHEN empTxn.TransactionType IN ('CashSales', 'Deposit', 'CollectionFromReceivable', 'MaternityAllowanceReturn', 'CashDiscountReceived')
							THEN ISNULL(SUM(ISNULL(empTxn.InAmount,0)) - ISNULL(SUM(ISNULL(empTxn.OutAmount,0)),0),0)
						WHEN empTxn.TransactionType IN ('SalesReturn', 'CashDiscountGiven', 'MaternityAllowance','ReturnDeposit')
							THEN SUM(ISNULL(empTxn.OutAmount,0))
					END 'NetTotal'					
					FROM TXN_EmpCashTransaction empTxn
					INNER JOIN MST_PaymentModes pModes
					ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
					INNER JOIN EMP_Employee emp
					ON emp.EmployeeId = empTxn.EmployeeId
					WHERE empTxn.TransactionType != 'HandoverGiven'
					AND CONVERT(DATE,empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
					AND pModes.PaymentSubCategoryName != 'Deposit'
					AND (@User IS NULL OR @User = 0 OR emp.EmployeeId = @User)
					GROUP BY empTxn.TransactionType, pModes.PaymentSubCategoryName
			) txn 
			PIVOT(
			SUM(txn.NetTotal)
			FOR txn.TransactionType IN (
				[CashSales], 
				[SalesReturn], 
				[Deposit],
				[ReturnDeposit],
				[CashDiscountGiven],
				[CashDiscountReceived],
				[MaternityAllowance],
				[MaternityAllowanceReturn],
				[CollectionFromReceivable]
				)
			) AS PaymentModeReportSummary;
	END