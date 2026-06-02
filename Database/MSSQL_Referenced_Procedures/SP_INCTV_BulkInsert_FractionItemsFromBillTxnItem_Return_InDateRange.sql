CREATE PROCEDURE [dbo].[SP_INCTV_BulkInsert_FractionItemsFromBillTxnItem_Return_InDateRange] (
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	)
AS
/*  
 File: SP_INCTV_BulkInsert_FractionItemsFromBillTxnItem_Return_InDateRange '2020-02-14','2020-02-14'  
 Description: To insert negative amount for Invoice Return Cases.  
           -- Negative Amount for:  TotalBillAmount, IncentiveAmount and TDS  
     -- IncentivePercent will remain same  
 Remarks:    
     * MainDoctor=1 for Assigned and is 0 for Referral.  
     * Check for CreatedBy and CreatedOn value.   
  * We're excluding the fraction where RequestsedBy(ReferredBy) and AssignedToId are there in BillingTxnItem but those doctors don't have any configuration in Incentive-Profile  
  
 Revision Needed ON:   
    * We may need undo functionality of this feature.  
 Change History:  
 S.No.    ChangeDate/By				Remarks  
1.        24Sept'20					This handles only Returned Items.  
2.        2 July'2021/pratik		Adding quantity to maintain partial return scenario from credit note  
3.        sud/Krishna:23Feb'22		Insert/check data from BillReturnItemId column of fraction 
									table to handle multiple return of same invoice item(Wecare issue)  
4.        2Jun'22, Krishna   
5.	      5thJUL'22,Krishna			Changed assigned to performer, referral to prescriber and added referral 
6.        23Aug'22, DevN			> Added logic to insert ReferrerDistribution and Calculation as well. 
									> Added value in Quantity field 
									> Handled DivideByZero issue for TotalAmount = 0
7.        14Aug'23,Nirmala			Change BillItemPriceId To ServiceItemId
8.		  22ndSept'23, Krishna		Add PriceCategory as Predicate to fetch PriceCategory wise Settings
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
			,Quantity
			,IsReturnTxn
			,BillReturnItemId
			)
		--Section: 1-- Start: For Referral Incentive (Group distribnution not required for referral)----------
		SELECT
			fyear.FiscalYearFormatted + '-' + retTxn.InvoiceCode + cast(retTxn.RefInvoiceNum AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,rettxn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,retTxn.BillingTransactionId
			,retItm.BillingTransactionItemId
			,retTxn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,- retItm.RetTotalAmount 'TotalBillAmount'
			,'prescriber' AS IncentiveType
			,retItm.PrescriberId 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.PrescriberPercent 'IncentivePercent'
			,- (
				retItm.RetTotalAmount - (
					retItm.RetTotalAmount * ISNULL((
							SELECT TOP (1) ReferrerPercent
							FROM INCTV_MAP_EmployeeBillItemsMap
							WHERE ServiceItemId = sett.ServiceItemId
								AND EmployeeId = txnItem.ReferredById
							), 0) / 100
					)
				) * ISNULL(sett.PrescriberPercent, 0) / 100 'IncentiveAmount'
			,CASE 
				WHEN retItm.RetTotalAmount <> 0
					THEN (((retItm.RetTotalAmount - (retItm.RetTotalAmount * ISNULL((SELECT TOP (1) ReferrerPercent FROM INCTV_MAP_EmployeeBillItemsMap WHERE                                         ServiceItemId = sett.ServiceItemId AND EmployeeId = txnItem.ReferredById), 0) / 100)) * ISNULL                                                    (sett.PrescriberPercent, 0) / 100) / retItm.RetTotalAmount) * 100
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
			,- (retItm.RetTotalAmount * ISNULL(sett.PrescriberPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,retItm.RetQuantity
			,1 AS IsReturnTxn
			,retItm.BillReturnItemId
		FROM BIL_TXN_InvoiceReturn retTxn
		INNER JOIN BIL_TXN_InvoiceReturnItems retItm
			--ON retTxn.BillingTransactionId=retItm.BillingTransactionId
			--sud/Krishna:23Feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
			ON retTxn.BillReturnId = retItm.BillReturnId
		INNER JOIN BIL_TXN_BillingTransactionItems txnItem ON retItm.BillingTransactionItemId = txnItem.BillingTransactionItemId
		INNER JOIN PAT_Patient pat ON retTxn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON retTxn.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON retItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND retItm.ServiceItemId = sett.ServiceItemId
			AND retItm.PrescriberId = sett.EmployeeId
			AND retItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = retItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, retTxn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.PrescriberPercent, 0) != 0
			--and retItm.BillingTransactionItemId  NOT IN 
			--  (SELECT DISTINCT BillingTransactionItemId  FROM INCTV_TXN_IncentiveFractionItem  WHERE IsReturnTxn=1) 
			AND retItm.BillReturnItemId NOT IN (
				SELECT DISTINCT BillReturnItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE BillReturnItemId IS NOT NULL
					AND IsReturnTxn = 1
				)
		--Section: 1-- END: For Referral Incentive (Group distribnution not required for referral)----------
		
		UNION ALL
		
		SELECT
			fyear.FiscalYearFormatted + '-' + retTxn.InvoiceCode + cast(retTxn.RefInvoiceNum AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,rettxn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,retTxn.BillingTransactionId
			,retItm.BillingTransactionItemId
			,retTxn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,- retItm.RetTotalAmount 'TotalBillAmount'
			,'performer' AS IncentiveType
			,retItm.PerformerId 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.PerformerPercent 'IncentivePercent'
			,-(retItm.RetTotalAmount -(retItm.RetTotalAmount * ISNULL((SELECT TOP (1) ReferrerPercent FROM INCTV_MAP_EmployeeBillItemsMap 
				                      WHERE ServiceItemId = sett.ServiceItemId AND EmployeeId = txnItem.ReferredById), 0) / 100)) * ISNULL(sett.PerformerPercent,0) /100 'IncentiveAmount'
			,CASE 
				WHEN retItm.RetTotalAmount <> 0
					THEN (((retItm.RetTotalAmount -(retItm.RetTotalAmount * ISNULL((SELECT TOP (1) ReferrerPercent FROM INCTV_MAP_EmployeeBillItemsMap
												   WHERE ServiceItemId = sett.ServiceItemId AND EmployeeId = txnItem.ReferredById), 0) / 100)) * ISNULL
												   (sett.PerformerPercent, 0) / 100) / retItm.RetTotalAmount) * 100
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
			,- (retItm.RetTotalAmount * ISNULL(sett.PerformerPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,retItm.RetQuantity
			,1 AS IsReturnTxn
			,retItm.BillReturnItemId
		FROM BIL_TXN_InvoiceReturn retTxn
		INNER JOIN BIL_TXN_InvoiceReturnItems retItm ON retTxn.BillReturnId = retItm.BillReturnId
		--ON retTxn.BillingTransactionId=retItm.BillingTransactionId
		--sud/Krishna:23Feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
		INNER JOIN BIL_TXN_BillingTransactionItems txnItem ON retItm.BillingTransactionItemId = txnItem.BillingTransactionItemId
		INNER JOIN PAT_Patient pat ON retTxn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON retTxn.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON retItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND retItm.ServiceItemId = sett.ServiceItemId
			AND retItm.PerformerId = sett.EmployeeId
			AND retItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = retItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, retTxn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.PerformerPercent, 0) != 0
			--and retItm.BillingTransactionItemId NOT IN 
			--    (SELECT DISTINCT BillingTransactionItemId FROM INCTV_TXN_IncentiveFractionItem  WHERE IsReturnTxn=1) 
			AND retItm.BillReturnItemId NOT IN (
				SELECT DISTINCT BillReturnItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE BillReturnItemId IS NOT NULL
					AND IsReturnTxn = 1
				)
		
		UNION ALL
		
		--Section: 3-- Start: For Referral Incentive----------
		SELECT
			fyear.FiscalYearFormatted + '-' + retTxn.InvoiceCode + cast(retTxn.RefInvoiceNum AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,rettxn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,retTxn.BillingTransactionId
			,retItm.BillingTransactionItemId
			,retTxn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,- retItm.RetTotalAmount 'TotalBillAmount'
			,'referral' AS IncentiveType
			,txnItem.ReferredById 'IncentiveReceiverId'
			,sett.FullName 'IncentiveReceiverName'
			,sett.ReferrerPercent 'IncentivePercent'
			,- (retItm.RetTotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100) 'IncentiveAmount'
			,CASE 
				WHEN retItm.RetTotalAmount <> 0
					THEN (((retItm.RetTotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100) / retItm.RetTotalAmount) * 100)
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
			,- (retItm.RetTotalAmount * ISNULL(sett.ReferrerPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,retItm.RetQuantity
			,1 AS IsReturnTxn
			,retItm.BillReturnItemId
		FROM BIL_TXN_InvoiceReturn retTxn
		INNER JOIN BIL_TXN_InvoiceReturnItems retItm
			--ON retTxn.BillingTransactionId=retItm.BillingTransactionId
			--sud/Krishna:23Feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
			ON retTxn.BillReturnId = retItm.BillReturnId
		INNER JOIN BIL_TXN_BillingTransactionItems txnItem ON retItm.BillingTransactionItemId = txnItem.BillingTransactionItemId
		INNER JOIN PAT_Patient pat ON retTxn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON retTxn.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_Normal() sett ON retItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND retItm.ServiceItemId = sett.ServiceItemId
			AND txnItem.ReferredById = sett.EmployeeId
			AND retItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = retItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, retTxn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.ReferrerPercent, 0) != 0
			--and retItm.BillingTransactionItemId  NOT IN 
			--  (SELECT DISTINCT BillingTransactionItemId  FROM INCTV_TXN_IncentiveFractionItem  WHERE IsReturnTxn=1) 
			AND retItm.BillReturnItemId NOT IN (
				SELECT DISTINCT BillReturnItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE BillReturnItemId IS NOT NULL
					AND IsReturnTxn = 1
				)
		--Section: 1-- END: For Referral Incentive (Group distribnution not required for referral)----------
		
		UNION ALL
		
		SELECT
			fyear.FiscalYearFormatted + '-' + retTxn.InvoiceCode + cast(retTxn.RefInvoiceNum AS VARCHAR(20)) AS 'InvoiceNoFormatted'
			,rettxn.CreatedOn 'TransactionDate'
			,sett.PriceCategoryName 'PriceCategory'
			,retTxn.BillingTransactionId
			,BillingTransactionItemId
			,retTxn.PatientId
			,sett.ServiceItemId
			,sett.ItemName
			,- retItm.RetTotalAmount 'TotalBillAmount'
			,'performer' AS IncentiveType
			,
			-- incentive goes to:  ToEmployeeId----
			sett.ToEmployeeId 'IncentiveReceiverId'
			,sett.ToEmployeeName 'IncentiveReceiverName'
			,sett.DistributionPercent 'IncentivePercent'
			,- retItm.RetTotalAmount * ISNULL(sett.DistributionPercent, 0) / 100 'IncentiveAmount'
			,((retItm.RetTotalAmount * ISNULL(sett.DistributionPercent, 0) / 100) / retItm.RetTotalAmount) * 100 'InitialIncentivePercent'
			,0 AS IsPaymentProcessed
			,NULL AS PaymentInfoId
			,1 AS CreatedBy
			,GetDate() AS CreatedOn
			,NULL AS ModifiedBy
			,NULL AS ModifiedOn
			,1 AS IsActive
			,1 AS IsMainDoctor
			,ISNULL(sett.TDSPercent, 0) AS TDSPercentage
			,- (retItm.RetTotalAmount * ISNULL(sett.DistributionPercent, 0) / 100) * ISNULL(sett.TDSPercent, 0) / 100 AS 'TDSAmount' -- TDSAmount=IncentiveAmt*TDSPercent/100
			,retItm.RetQuantity
			,1 AS IsReturnTxn
			,retItm.BillReturnItemId
		FROM BIL_TXN_InvoiceReturn retTxn
		INNER JOIN BIL_TXN_InvoiceReturnItems retItm ON retTxn.BillReturnId = retItm.BillReturnId
		--ON retTxn.BillingTransactionId=retItm.BillingTransactionId
		--sud/Krishna:23Feb'22: BugFix (When more than one item returned from same bill then it's giving one item multiple times)
		INNER JOIN PAT_Patient pat ON retTxn.PatientId = pat.PatientId
		INNER JOIN BIL_CFG_FiscalYears fyear ON retTxn.FiscalYearId = fyear.FiscalYearId
		INNER JOIN FN_INCTV_GetIncentiveSettings_GroupDistribution() sett -- this gives us group distribution settings only.. 
			--[FN_INCTV_GetIncentiveSettings] () sett
			ON retItm.ServiceDepartmentId = sett.ServiceDepartmentId
			AND retItm.ServiceItemId = sett.ServiceItemId
			AND retItm.PerformerId = sett.FromEmployeeId
			AND retItm.PriceCategoryId = sett.PriceCategoryId
			AND 1 = (
				CASE 
					WHEN ISNULL(sett.BillingTypesApplicable, 'both') = 'both'
						THEN 1
					WHEN sett.BillingTypesApplicable = retItm.BillingType
						THEN 1
					ELSE 0
					END
				)
		WHERE Convert(DATE, retTxn.CreatedOn) BETWEEN @FromDate
				AND @ToDate
			AND ISNULL(sett.DistributionPercent, 0) != 0
			--and retItm.BillingTransactionItemId NOT IN 
			--    (SELECT DISTINCT BillingTransactionItemId FROM INCTV_TXN_IncentiveFractionItem  WHERE IsReturnTxn=1) 
			AND retItm.BillReturnItemId NOT IN (
				SELECT DISTINCT BillReturnItemId
				FROM INCTV_TXN_IncentiveFractionItem
				WHERE BillReturnItemId IS NOT NULL
					AND IsReturnTxn = 1
				)
	END --end of IF.. 
			--by default returning something so that we understand it has been executed..

	SELECT 'success' AS 'status'
END --end of SP--