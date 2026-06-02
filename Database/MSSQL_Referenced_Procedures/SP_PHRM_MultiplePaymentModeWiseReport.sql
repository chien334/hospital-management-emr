CREATE PROCEDURE [dbo].[SP_PHRM_MultiplePaymentModeWiseReport]
		@FromDate DATE, 
		@ToDate DATE,
		@PaymentMode NVARCHAR(20) = NULL,
		@Type NVARCHAR(30) = NULL,
		@User INT = NULL,
		@StoreId INT =NULL

	/*
	FileName: [SP_PHRM_MultiplePaymentModeWiseReport]
	CreatedBy/date: KRISHNA/2022-07-20
	Description: To get the Multiple Payment Mode wise Report (Cash Sales, Deposit Received and Credit Settlement) except for Cash Payment Method
	//Execution Example : EXECUTE SP_PHRM_MultiplePaymentModeWiseReport '2022-07-27', '2022-08-05',NULL,NULL, NULL,42


	Change History
	S.No.    UpdatedBy/Date                        Remarks
	1.		KRISHNA/2022-07-20						initial draft
	2.		KRISHNA/2022-07-25						Added User Filter for Summary Data
	3.      ROHIT/28Jul'22						    (CreditNoteNo->InvoiceReturnId, InvoicePrintId-> InvoiceId) matching condition changed
	4.	    Rohit/2022-08-05						StoreId filter is added

	*/
	AS
	BEGIN
	IF @PaymentMode = 'All'
			BEGIN
			SET @PaymentMode = NULL;
		END

		IF @Type = 'All'
			BEGIN
			SET @Type = NULL;
		END
	SELECT *
		FROM (
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'CashSales' THEN 'Cash Sales'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'CashSales' THEN CONCAT ('PH','-',txn.InvoicePrintId)
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
					,txn.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_TXN_Invoice txn ON txn.InvoiceId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = txn.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CashSales'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
	
			UNION
			(SELECT CONVERT(DATE, empTxn.TransactionDate) 'Date'
					,CASE 
						WHEN empTxn.TransactionType = 'DepositAdd' THEN 'Deposit Received'
					 END 'Type'
					,pModes.PaymentSubCategoryName 'PaymentMode'
					,CASE 
						WHEN empTxn.TransactionType = 'DepositAdd' THEN CONVERT(VARCHAR(50), dep.ReceiptNo)
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
					,dep.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_Deposit dep ON dep.DepositId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = dep.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'DepositAdd'
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
					,sett.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_TXN_Settlement sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
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
						WHEN empTxn.TransactionType = 'SalesReturn' THEN CONCAT ('CR','-',ret.InvoiceReturnId)
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
					,ret.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_TXN_InvoiceReturn ret ON ret.InvoiceReturnId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = ret.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
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
					,dep.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_Deposit dep ON dep.DepositId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = dep.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
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
					,sett.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_TXN_Settlement sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
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
					,sett.StoreId
				FROM PHRM_EmployeeCashTransaction empTxn
						INNER JOIN PHRM_TXN_Settlement sett ON sett.SettlementId = empTxn.ReferenceNo
						INNER JOIN PAT_Patient pat ON pat.PatientId = sett.PatientId
						INNER JOIN EMP_Employee emp ON emp.EmployeeId = empTxn.EmployeeId
						INNER JOIN MST_PaymentModes pModes ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
						INNER JOIN PHRM_MST_Counter cntr ON cntr.CounterId = empTxn.CounterID
						WHERE empTxn.TransactionType = 'CashDiscountReceived'
							AND pModes.PaymentSubCategoryName != 'Deposit'
							AND CONVERT(DATE, empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
				)
			) tbl
		WHERE 
			(tbl.PaymentMode = @PaymentMode OR @PaymentMode IS NULL)
			AND (tbl.Type = @Type OR @Type IS NULL)
			AND (tbl.EmployeeId = @User OR @User IS NULL)
			AND (tbl.StoreId=@StoreId OR @StoreId IS NULL)
		ORDER BY tbl.DATE DESC

		SELECT
			PaymentModes,
			ISNULL(CashSales,0) 'CashSales',
			ISNULL(SalesReturn,0)'ReturnCashSales',
			ISNULL(DepositAdd,0) 'DepositReceived',
			ISNULL(ReturnDeposit,0)'DepositRefund',
			(ISNULL(CashDiscountGiven,0) - ISNULL(CashDiscountReceived,0))'SettlementDiscount',
			
			ISNULL(CollectionFromReceivable,0) 'CollectionFromReceivable',

			--Calculation for Cash Collection--
			ISNULL(CashSales,0) - ISNULL(SalesReturn,0)
			+ ISNULL(DepositAdd,0) - ISNULL(ReturnDeposit,0)
			+ ISNULL(CollectionFromReceivable,0)
			- (ISNULL(CashDiscountGiven,0) - ISNULL(CashDiscountReceived,0))
			AS 'CashCollection'
		FROM   
			(SELECT 
					empTxn.TransactionType,
					pModes.PaymentSubCategoryName 'PaymentModes',
					CASE 
						WHEN empTxn.TransactionType IN ('CashSales', 'DepositAdd', 'CollectionFromReceivable', 'CashDiscountReceived')
							THEN ISNULL(SUM(ISNULL(empTxn.InAmount,0)) - ISNULL(SUM(ISNULL(empTxn.OutAmount,0)),0),0)
						WHEN empTxn.TransactionType IN ('SalesReturn', 'CashDiscountGiven','ReturnDeposit')
							THEN SUM(ISNULL(empTxn.OutAmount,0))
					END 'NetTotal'					
					FROM PHRM_EmployeeCashTransaction empTxn
					INNER JOIN MST_PaymentModes pModes
					ON pModes.PaymentSubCategoryId = empTxn.PaymentModeSubCategoryId
					INNER JOIN EMP_Employee emp
					ON emp.EmployeeId = empTxn.EmployeeId
					INNER JOIN PHRM_TXN_Invoice inv ON empTxn.ReferenceNo=inv.InvoiceId
					WHERE CONVERT(DATE,empTxn.TransactionDate) BETWEEN @FromDate AND @ToDate
					AND pModes.PaymentSubCategoryName != 'Deposit'
					AND (emp.EmployeeId = @User OR @User IS NULL)
					AND (inv.StoreId=@StoreId OR @StoreId IS NULL)
					GROUP BY empTxn.TransactionType, pModes.PaymentSubCategoryName
			) txn 
			PIVOT(
			SUM(txn.NetTotal)
			FOR txn.TransactionType IN (
				[CashSales], 
				[SalesReturn], 
				[DepositAdd],
				[ReturnDeposit],
				[CashDiscountGiven],
				[CashDiscountReceived],
				[CollectionFromReceivable]
				)
			) AS PaymentModeReportSummary;
	END