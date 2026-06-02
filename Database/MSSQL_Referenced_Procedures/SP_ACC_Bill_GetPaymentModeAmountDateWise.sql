CREATE PROCEDURE [dbo].[SP_ACC_Bill_GetPaymentModeAmountDateWise] @TransactionDate DATE
		,@HospitalId INT
	AS
		/**************************************************
		Stored Procedure Name:SP_ACC_Bill_GetPaymentModeAmountDateWise	
		Execution:
		exec [SP_ACC_Bill_GetPaymentModeAmountDateWise] '2022-06-04',1
		Details:
		-This stored procedure will get Payment mode data and Amounts for transfer to accounting by date
		-We are getting billing records, deposit records, etc
		

			Change History:
			S.No.   Author					Date				 Remarks
			1.      Krishna					9thMarch'22			Stored procedure created
			2.		Bikash/Krishna			10thMarch'22		Transaction type change according to Accounting Rules
			3.		Bikash					11thMarch'22		LedgerId added - according to Ledger Mapping with different Payment Modes 
			4.      Dev Narayan             24thMay'22          Added Credit Organization Id for Crdit bill paid (i.e. settlement)
			5.      DevN					19th May 23         ModuleName filter added for billing deposits.
		**********************************************/
	BEGIN
	DECLARE @BillTxnIdsCSV NVARCHAR(MAX)
		,@DepositIdsCSV NVARCHAR(MAX)
		,@DepositDeductIdsCSV NVARCHAR(MAX)
		,@DepositReturnIdsCSV NVARCHAR(MAX)
		,@SettlementIdsCSV NVARCHAR(MAX)
		,@SalesReturnIdsCSV NVARCHAR(MAX)
		,@CashDiscountReturnSettlementIdsCSV NVARCHAR(MAX);

	SET @BillTxnIdsCSV = (
			SELECT STRING_AGG(CAST(BillingTransactionId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_BillingTransaction
			WHERE BillingTransactionId IN (
					SELECT DISTINCT BillingTransactionId
					FROM BIL_TXN_BillingTransactionItems
					WHERE ISNULL(IsCashBillSync, 0) = 0
						AND CONVERT(DATE, PaidDate) = CONVERT(DATE,@TransactionDate)
					)
			)
	--Setting DepositIds into @DepositIdsCSV 
	SET @DepositIdsCSV = (
			SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_Deposit
			WHERE DepositId IN (
					SELECT DISTINCT DepositId
					FROM BIL_TXN_Deposit
					WHERE TransactionType = 'Deposit'
						AND ISNULL(IsDepositSync, 0) = 0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
						AND ModuleName = 'Billing'
					)
			)
	--Setting DepositDeductIds into @DepositDeductIdsCSV 
	SET @DepositDeductIdsCSV = (
			SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_Deposit
			WHERE DepositId IN (
					SELECT DISTINCT DepositId
					FROM BIL_TXN_Deposit
					WHERE TransactionType = 'depositdeduct'
						AND ISNULL(IsDepositSync, 0) = 0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
						AND ModuleName = 'Billing'
					)
			)
	--Setting DepositReturnIds into @DepositReturnIdsCSV 
	SET @DepositReturnIdsCSV = (
			SELECT STRING_AGG(CAST(DepositId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_Deposit
			WHERE DepositId IN (
					SELECT DISTINCT DepositId
					FROM BIL_TXN_Deposit
					WHERE TransactionType = 'ReturnDeposit'
						AND ISNULL(IsDepositSync, 0) = 0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
						AND ModuleName = 'Billing'
					)
			)
	--Setting SettlementIds into @SettlementIdsCSV 
	SET @SettlementIdsCSV = (
			SELECT STRING_AGG(CAST(SettlementId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_Settlements
			WHERE SettlementId IN (
					SELECT DISTINCT SettlementId
					FROM BIL_TXN_Settlements
					WHERE ISNULL(IsSyncToAcc, 0) = 0
						AND ISNULL(CollectionFromReceivable,0)>0
						AND ISNULL(DiscountReturnAmount,0)=0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
					)
			)


--Setting SettlementIds for  into @CashDiscountReturnSettlementIdsCSV
	SET @CashDiscountReturnSettlementIdsCSV = (
			SELECT STRING_AGG(CAST(SettlementId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_Settlements
			WHERE SettlementId IN (
					SELECT DISTINCT SettlementId
					FROM BIL_TXN_Settlements
					WHERE ISNULL(IsSyncToAcc, 0) = 0
						AND ISNULL(CollectionFromReceivable,0)=0
						AND ISNULL(DiscountReturnAmount,0)>0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
					)
			)

	--Setting InvoiceReturnIds into @SalesReturnIdsCSV
	SET @SalesReturnIdsCSV = (
			SELECT STRING_AGG(CAST(BillReturnId AS NVARCHAR(MAX)), ',')
			FROM BIL_TXN_InvoiceReturnItems
			WHERE BillReturnId IN (
					SELECT DISTINCT BillReturnId
					FROM BIL_TXN_InvoiceReturnItems
					WHERE ISNULL(IsCashBillSyncToAcc, 0) = 0
						AND CONVERT(DATE, CreatedOn) = CONVERT(DATE, @TransactionDate)
					)
			)

	SELECT modes.PaymentSubCategoryName
		,'CashBill' as TransactionType
		,ISNULL(SUM(InAmount),0) 'TotalAmount'
		,LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType = 'CashSales'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@BillTxnIdsCSV, ',')
			)
		
	GROUP BY modes.PaymentSubCategoryName, lm.LedgerId

	
	UNION ALL
	
	SELECT modes.PaymentSubCategoryName
		,'DepositAdd' as TransactionType
		,ISNULL(SUM(InAmount),0)  'TotalAmount'
		,LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType = 'Deposit'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@DepositIdsCSV, ',')
			)
	GROUP BY modes.PaymentSubCategoryName,lm.LedgerId
	
	UNION ALL
	
	SELECT modes.PaymentSubCategoryName
		,'DepositDeduct' as TransactionType
		,ISNULL(SUM(OutAmount),0)  'TotalAmount'
		, LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType = 'depositdeduct'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@DepositDeductIdsCSV, ',')
			)
	GROUP BY modes.PaymentSubCategoryName, lm.LedgerId
	
	UNION ALL
	
	SELECT modes.PaymentSubCategoryName
		,'DepositReturn' as TransactionType
		,ISNULL(SUM(OutAmount),0)  'TotalAmount'
		,LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType = 'ReturnDeposit'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@DepositReturnIdsCSV, ',')
			)
	GROUP BY modes.PaymentSubCategoryName, lm.LedgerId
	
	UNION ALL
	
	
	
	SELECT modes.PaymentSubCategoryName
		,'CreditBillPaid' as TransactionType
		,ISNULL(SUM(InAmount),0) - ISNULL(SUM(OutAmount),0) 'TotalAmount'
		,lm.LedgerId
		,settl.OrganizationId
	FROM BIL_TXN_Settlements settl
	JOIN TXN_EmpCashTransaction cash on settl.SettlementId = cash.ReferenceNo
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType in  ('CollectionFromReceivable','CashDiscountGiven')
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@SettlementIdsCSV, ',') -- settlementId ref
			)
	GROUP BY modes.PaymentSubCategoryName, lm.LedgerId,settl.OrganizationId
	
	UNION ALL
	
	SELECT modes.PaymentSubCategoryName
		,'CashBillReturn' as TransactionType
		,ISNULL(SUM(OutAmount),0)  'TotalAmount'
		,LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	LEFT JOIN ACC_Ledger_Mapping lm ON modes.PaymentSubCategoryId = lm.ReferenceId and lm.LedgerType ='paymentmodes' and lm.HospitalId =@HospitalId
	WHERE TransactionType = 'SalesReturn'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@SalesReturnIdsCSV, ',')
			)
	GROUP BY modes.PaymentSubCategoryName, lm.LedgerId
	UNION ALL
	
	SELECT modes.PaymentSubCategoryName
		,'DiscountReturn' as TransactionType
		,ISNULL(SUM(InAmount),0)  'TotalAmount'
		, 0 as LedgerId
		,NULL as OrganizationId
	FROM TXN_EmpCashTransaction cash
	INNER JOIN MST_PaymentModes modes ON cash.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	WHERE TransactionType = 'CashDiscountReceived'
		AND ReferenceNo IN (
			SELECT VALUE
			FROM STRING_SPLIT(@CashDiscountReturnSettlementIdsCSV, ',') -- settlementId ref
			)
	GROUP BY modes.PaymentSubCategoryName
END