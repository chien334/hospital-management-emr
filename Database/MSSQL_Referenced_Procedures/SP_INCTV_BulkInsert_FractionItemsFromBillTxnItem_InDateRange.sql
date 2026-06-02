CREATE PROCEDURE [dbo].[SP_INCTV_BulkInsert_FractionItemsFromBillTxnItem_InDateRange] (
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	)
AS
/*
 File: SP_INCTV_BulkInsert_FractionItemsFromBillTxnItem_InDateRange '2020-02-14','2020-02-14'
 Description: 
 Remarks:  
     * MainDoctor=1 for Assigned and is 0 for Referral.
     * Check for CreatedBy and CreatedOn value. 
	 * We're excluding the fraction where RequestsedBy(ReferredBy) and AssignedToId are there in BillingTxnItem but those doctors don't have any configuration in Incentive-Profile

 Revision Needed ON: 
    * We may need undo functionality of this feature.
 Change History:
S.No.    ChangeDate/By						Remarks
 1.      15Feb'20/Sud						Initial Draft (Needs Revision)
 2.      15Mar'20/Sud						Added TDSPercentage and TDSAmount calculation in the query
3.       4Apr'20/Sud						Excluding Already Added BillingTransactionItem during Bill Sync.
											earlier it was at BillingTransactionId level, now it's BillingTransactionItemId
4.       11June								TDSpercentage from Employee Incentive Info
5.       17Jul'20/Sud/Pratik				Updated for Group Distribution 
6.       10Aug'20/Sud						Removed HardCoded Date Range from Group Distribution
7.       17Sept'20							Temporary solution to avoid Syncing Returned items
											ToDate <= GetDate()-5days or less.. if not then make that from here..
8.       24Sept'20							Returned items not excluded anymore, it will be handled by another 
											StoredProcedure as Negative billing
9.       2 July'2021  /pratik				Adding quantity to maintain partial return scenario from credit note
10.		 2Jun'22 Krishna					Changed AssignedToPercent to PerformerPercent, ReferredByPercent to 
											PrescriberPercent, ProviderId to PerformerId
11.      23Aug'22, DevN						> Added logic for incentive calculation after referral deduction. 
											> Handled DivideByZero issue for TotalAmount = 0
12.      17Oct'22, Dev N					Changed IncentiveReceiverId In Referral Section From PrescriberId to ReferredById
13.      14Aug'22, Nirmala					Change BillItemPriceId to ServiceItemId
14.		 22ndSept'23, Krishna				Add PriceCategoryId as predicate to get PriceCategory wise settings
*/
BEGIN
	IF (@FromDate IS NOT NULL AND @ToDate IS NOT NULL)
	BEGIN
		INSERT INTO INCTV_TXN_IncentiveFractionItem (
			InvoiceNoFormatted
			,TransactionDate
			,PriceCategory
			,BillingTransactionId
			,BillingTransactionItemId
			,PatientId
			,ServiceItemId
			,ItemName
			,TotalBillAmount
			,IncentiveType
			,IncentiveReceiverId
			,IncentiveReceiverName
			,FinalIncentivePercent
			,IncentiveAmount
			,InitialIncentivePercent
			,IsPaymentProcessed
			,PaymentInfoId
			,CreatedBy
			,CreatedOn
			,ModifiedBy
			,ModifiedOn
			,IsActive
			,IsMainDoctor
			,TDSPercentage
			,TDSAmount
			,IsReturnTxn
			,Quantity
			)
		SELECT
			fyear.FiscalYearFormatted + '-' + txn.InvoiceCode + cast(txn.InvoiceNo AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,txn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,txn.BillingTransactionId
			,txnItm.BillingTransactionItemId
			,txn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,txnItm.TotalAmount 'TotalBillAmount'
			,'prescriber' AS IncentiveType
			,txnItm.PrescriberId 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.PrescriberPercent 'FinalIncentivePercent'
			,(
				txnitm.TotalAmount - (txnitm.TotalAmount * ISNULL((SELECT TOP (1) ReferrerPercent FROM INCTV_MAP_EmployeeBillItemsMap WHERE ServiceItemId =                                sett.ServiceItemId AND EmployeeId = txnItm.ReferredById), 0) / 100)) * ISNULL(sett.PrescriberPercent, 0) / 100 'IncentiveAmount'
			,CASE 
				WHEN txnitm.TotalAmount <> 0
					THEN (((txnitm.TotalAmount -(txnitm.TotalAmount * ISNULL((
												SELECT TOP (1) ReferrerPercent
												FROM INCTV_MAP_EmployeeBillItemsMap
												WHERE ServiceItemId = sett.ServiceItemId
												AND EmployeeId = txnItm.ReferredById), 0) / 100)) * ISNULL(sett.PrescriberPercent, 0) / 100) / txnitm.TotalAmount) * 100
				ELSE 0
				END AS 'InitialIncentivePercent'
			,0 AS IsPaymentProcessed
			,NULL AS PaymentInfoId
			,1 AS CreatedBy
			,GetDate() AS CreatedOn
			,NULL AS ModifiedBy
			,NULL AS ModifiedOn
			,1 AS IsActive
			,0 AS IsMainDoctor
			,ISNULL(sett.TDSPercent, 0) AS TDSPercent
			,(txnitm.TotalAmount * ISNULL(sett.PrescriberPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,0 AS IsReturnTxn
			,txnItm.Quantity
		-- ,txnitm.ServiceDepartmentId, txnitm.ServiceDepartmentName, txnitm.ItemId, txnItm.SubTotal, txnItm.DiscountAmount,
		-- pat.FirstName+' '+pat.LastName 'PatientName'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN BIL_TXN_BillingTransactionItems txnItm ON txn.BillingTransactionId = txnItm.BillingTransactionId
		INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON TXN.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON txnItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND txnItm.ServiceItemId = sett.ServiceItemId
			AND txnItm.PrescriberId = sett.EmployeeId
			AND txnItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = txnItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
					--AND ISNULL(txnItm.ReturnStatus,0)= 0 -- Not Required Anymore
			AND ISNULL(sett.PrescriberPercent, 0) != 0
			AND txnItm.BillingTransactionItemId NOT IN (
				SELECT DISTINCT BillingTransactionItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE IsReturnTxn = 0
				)
		
		UNION ALL
		
		SELECT
			fyear.FiscalYearFormatted + '-' + txn.InvoiceCode + cast(txn.InvoiceNo AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,txn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,txn.BillingTransactionId
			,BillingTransactionItemId
			,txn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,txnItm.TotalAmount 'TotalBillAmount'
			,'performer' AS IncentiveType
			,txnItm.PerformerId 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.PerformerPercent 'FinalIncentivePercent'
			,(
				txnitm.TotalAmount - (txnitm.TotalAmount * ISNULL((
							SELECT TOP (1) ReferrerPercent
							FROM INCTV_MAP_EmployeeBillItemsMap
							WHERE ServiceItemId = sett.ServiceItemId
						    AND EmployeeId = txnItm.ReferredById
							), 0) / 100
					)
				) * ISNULL(sett.PerformerPercent, 0) / 100 'IncentiveAmount'
			,CASE 
				WHEN txnitm.TotalAmount <> 0
					THEN (((txnitm.TotalAmount - (txnitm.TotalAmount * ISNULL((SELECT TOP (1) ReferrerPercent FROM INCTV_MAP_EmployeeBillItemsMap
												 WHERE ServiceItemId = sett.ServiceItemId AND EmployeeId = txnItm.ReferredById ), 0) / 100)) * ISNULL                          (sett.PerformerPercent, 0) / 100) / txnitm.TotalAmount) * 100
				ELSE 0
				END AS 'InitialIncentivePercent'
			,0 AS IsPaymentProcessed
			,NULL AS PaymentInfoId
			,1 AS CreatedBy
			,GetDate() AS CreatedOn
			,NULL AS ModifiedBy
			,NULL AS ModifiedOn
			,1 AS IsActive
			,1 AS IsMainDoctor
			,ISNULL(sett.TDSPercent, 0) AS TDSPercentage
			,(txnitm.TotalAmount * ISNULL(sett.PerformerPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,0 AS IsReturnTxn
			,txnItm.Quantity
		--, txnitm.ServiceDepartmentId, txnitm.ServiceDepartmentName, txnitm.ItemId, txnItm.SubTotal, txnItm.DiscountAmount,
		-- pat.FirstName+' '+pat.LastName 'PatientName'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN BIL_TXN_BillingTransactionItems txnItm ON txn.BillingTransactionId = txnItm.BillingTransactionId
		INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON TXN.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON txnItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND txnItm.ServiceItemId = sett.ServiceItemId
			AND txnItm.PerformerId = sett.EmployeeId
			AND txnItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = txnItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.PerformerPercent, 0) != 0
			AND txnItm.BillingTransactionItemId NOT IN (
				SELECT DISTINCT BillingTransactionItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE IsReturnTxn = 0
				) -- remove this condition once daily upload is enabled..
		
		UNION ALL
		
		SELECT
			fyear.FiscalYearFormatted + '-' + txn.InvoiceCode + cast(txn.InvoiceNo AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,txn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,txn.BillingTransactionId
			,BillingTransactionItemId
			,txn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,txnItm.TotalAmount 'TotalBillAmount'
			,'referral' AS IncentiveType
			,txnItm.ReferredById 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.ReferrerPercent 'FinalIncentivePercent'
			,txnitm.TotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100 'IncentiveAmount'
			,CASE 
				WHEN txnitm.TotalAmount <> 0
					THEN ((txnitm.TotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100) / txnitm.TotalAmount) * 100
				ELSE 0
				END AS 'InitialIncentivePercent'
			,0 AS IsPaymentProcessed
			,NULL AS PaymentInfoId
			,1 AS CreatedBy
			,GetDate() AS CreatedOn
			,NULL AS ModifiedBy
			,NULL AS ModifiedOn
			,1 AS IsActive
			,1 AS IsMainDoctor
			,ISNULL(sett.TDSPercent, 0) AS TDSPercentage
			,(txnitm.TotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,0 AS IsReturnTxn
			,txnItm.Quantity
		--, txnitm.ServiceDepartmentId, txnitm.ServiceDepartmentName, txnitm.ItemId, txnItm.SubTotal, txnItm.DiscountAmount,
		-- pat.FirstName+' '+pat.LastName 'PatientName'
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN BIL_TXN_BillingTransactionItems txnItm ON txn.BillingTransactionId = txnItm.BillingTransactionId
		INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON TXN.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON txnItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND txnItm.ServiceItemId = sett.ServiceItemId
			AND txnItm.ReferredById = sett.EmployeeId
			AND txnItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = txnItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.ReferrerPercent, 0) != 0
			AND txnItm.BillingTransactionItemId NOT IN (
				SELECT DISTINCT BillingTransactionItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE IsReturnTxn = 0
				) -- remove this condition once daily upload is enabled..
		
		UNION ALL
		
		SELECT
			fyear.FiscalYearFormatted + '-' + txn.InvoiceCode + cast(txn.InvoiceNo AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,txn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,txn.BillingTransactionId
			,BillingTransactionItemId
			,txn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,txnItm.TotalAmount 'TotalBillAmount'
			,'performer' AS IncentiveType
			,
			-- incentive goes to:  ToEmployeeId----
			sett.ToEmployeeId 'IncentiveReceiverId'
			,sett.ToEmployeeName 'IncentiveReceiverName'
			,sett.DistributionPercent 'FinalIncentivePercent'
			,txnitm.TotalAmount * ISNULL(sett.DistributionPercent, 0) / 100 'IncentiveAmount'
			,CASE 
				WHEN txnitm.TotalAmount <> 0
					THEN ((txnitm.TotalAmount * ISNULL(sett.DistributionPercent, 0) / 100) / txnitm.TotalAmount) * 100
				ELSE 0
				END AS 'InitialIncentivePercent'
			,0 AS IsPaymentProcessed
			,NULL AS PaymentInfoId
			,1 AS CreatedBy
			,GetDate() AS CreatedOn
			,NULL AS ModifiedBy
			,NULL AS ModifiedOn
			,1 AS IsActive
			,1 AS IsMainDoctor
			,ISNULL(sett.TDSPercent, 0) AS TDSPercentage
			,(txnitm.TotalAmount * ISNULL(sett.DistributionPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,0 AS IsReturnTxn
			,txnItm.Quantity
		FROM BIL_TXN_BillingTransaction txn
		INNER JOIN BIL_TXN_BillingTransactionItems txnItm ON txn.BillingTransactionId = txnItm.BillingTransactionId
		INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON TXN.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_GroupDistribution() sett -- this gives us group distribution settings only.. 
			--[FN_INCTV_GetIncentiveSettings] () sett
			ON txnItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND txnItm.ServiceItemId = sett.ServiceItemId
			AND txnItm.PerformerId = sett.FromEmployeeId
			AND txnItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = txnItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, txn.CreatedOn) BETWEEN @FromDate
				AND @ToDate -- sud:10Aug'20-- this dates were hardcoded earlier.
					-- AND ISNULL(txnItm.ReturnStatus,0)= 0 -- Not Required Anymore
			AND ISNULL(sett.DistributionPercent, 0) != 0
			AND txnItm.BillingTransactionItemId NOT IN (
				SELECT DISTINCT BillingTransactionItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE IsReturnTxn = 0
				) -- remove this condition once daily upload is enabled..
	END --end of IF.. 

	--by default returning something so that we understand it has been executed..
	SELECT 'success' AS 'status'
END --end of SP--