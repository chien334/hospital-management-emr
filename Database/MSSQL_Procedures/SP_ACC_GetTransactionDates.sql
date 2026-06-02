CREATE PROCEDURE [dbo].[SP_ACC_GetTransactionDates] --'2022-02-13', '2022-02-13',1,2
	@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@HospitalId INT = NULL
	,@SectionId INT = NULL
AS
/************************************************************************
	SP_ACC_GetTransactionDates '2023-06-16', '2023-07-1',1,1
	S.No.    UpdatedBy/Date                        Remarks
	1.      Vikas:25th Sep 2020				changed table for consumptions transactions from WARD_INV_Consumption to WARD_INV_Transaction
	2.      Vikas:30 Sep 2020				transaction dates mismatched and some other bugs correction from all tables.
	3.      Nagesh:01 Oct 2020              stockmanag out record date logic changed . Stock ManageOut only once in year on Fiscal Year end date and whole year data will show fiscal year enddate as transaction date
	4.		Nagesh:25 Dec 2020				Credit bill date gets wrong. Because here we taken CreatedOn from Item table but correct from Transaction table
	5.		NageshBB/Sanjit sir: 13July2021 updated after pharmacy, billing, inventory changes done in accounting 
	6.		Bikash : 31stJan2022			added transcation date of credit settlement (CreditBillPaid)
	7.		Bikash : 8thFeb2022				added transcation date of discount return when bill (either cash or credit) is returned. (DiscountReturn)
	8.		Bikash : 10thFeb2022			In "Credit Bill Return" condition logic changed to  Bill Status = "Unpaid" and "Paid" on "Cash Bill Return"
	9.      Dev Narayan 24th May 2022       Added Settlement table in pharmacy section
	10.     Dev Narayan 27th May 2022       Added PHRM Stock Adjustment table in Pharamcy section
	11.     Dev Narayan 3 June 2022         Changed SP For INV Fixed Assets.
	12.     DevN/19th May 23                DepositType Column of Billing Deposit table is Changed to TransactionType.
	13.     DevN/25th June 23               Removed TransactionType filter for transactionDate as we are using different set of transactiontypes now.
	14.     DevN/ 4th July 23               Added TransactionDate for SchmeRefund
	15.     DevN/7th, Aug 23'               Added transfer rule filter to get transactiondate for only active rules.
	16.     DevN/15th, Oct 23'              Separate Inventory Consumption and Dispatch in separate rules.

	*************************************************************************/
BEGIN
	-- check rules are mapped or not with transaction types
	DECLARE @Rules TABLE (
		GroupMappingId INT
		,Description VARCHAR(200)
		,TransferRuleId INT
		)

	INSERT INTO @Rules (
		GroupMappingId
		,Description
		,TransferRuleId
		)
	SELECT [GroupMappingId]
		,[Description]
		,[TransferRuleId]
	FROM (
		SELECT gm.GroupMappingId
			,gm.Description
			,TransferRuleId
		FROM ACC_MST_GroupMapping gm
		--JOIN ACC_MST_MappingDetail mp ON gm.GroupMappingId = mp.GroupMappingId
		JOIN ACC_MST_Hospital_TransferRules_Mapping r ON gm.GroupMappingId = r.TransferRuleId
		WHERE r.IsActive = 1
		GROUP BY gm.GroupMappingId
			,gm.Description
			,TransferRuleId
		) x

	IF (
			@FromDate IS NOT NULL
			AND @ToDate IS NOT NULL
			AND @HospitalId IS NOT NULL
			AND @SectionId IS NOT NULL
			) --AND @FromDate > '2022-01-14' AND @ToDate > '2022-01-14') 
	BEGIN
		IF (@SectionId = 1) -- Inventory Section 
		BEGIN
			--Table1: GoodReceipt
			SELECT CONVERT(DATE, gr.GoodsReceiptDate) AS 'TransactionDate'
			FROM INV_TXN_GoodsReceipt gr
			WHERE (
					ISNULL(gr.IsTransferredToACC,0) = 0
					)
				AND (
					CONVERT(DATE, gr.GoodsReceiptDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					)
				AND gr.IsCancel != 1 --excluded cancel gr	
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_Purchase'
						) > 0
					)
				
			UNION
			
			--Table2: WriteOffItems
			SELECT CONVERT(DATE, wr.CreatedOn) AS 'TransactionDate'
			FROM INV_TXN_WriteOffItems wr
			WHERE (
					ISNULL(IsTransferredToACC,0) = 0
					)
				AND (
					CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					)
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_WriteOff'
						) > 0
					)
			UNION
			
			--Table3: ReturnToVendor
			SELECT CONVERT(DATE, rv.CreatedOn) AS 'TransactionDate'
			FROM INV_TXN_ReturnToVendor rv
			WHERE (
					ISNULL(rv.IsTransferredToAcc,0) = 0
					)
				AND (
					CONVERT(DATE, rv.ReturnDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					)
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_PurchaseReturn'
						) > 0
					)
			
			UNION
			
			--Table4: DispatchToDept			 
			SELECT CONVERT(DATE, stkTxn.TransactionDate) AS 'TransactionDate'
			FROM INV_TXN_StockTransaction stkTxn
			JOIN INV_MST_Item itm ON stkTxn.ItemId = itm.ItemId
			WHERE (
					ISNULL(stkTxn.IsTransferredToACC,0) = 0
					)
				AND stkTxn.TransactionType IN (
					'dispatched-item-from'
					,'returned-item-from'
					)
				AND ISNULL(itm.IsFixedAssets,0) = 0
				AND (
					convert(DATE, stkTxn.TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					)
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_ConsumableDispatch'
						OR [Description] = 'INV_ConsumableDispatchReturn'
						) > 0
					)
			UNION
			
			-- Table 5 :INVDeptConsumedGoods
			SELECT CONVERT(DATE, stkTxn.TransactionDate) AS 'TransactionDate'
			FROM INV_TXN_StockTransaction stkTxn
			JOIN INV_MST_Item itm ON stkTxn.ItemId = itm.ItemId
			WHERE (
					ISNULL(stkTxn.IsTransferredToACC,0) = 0
					)
				AND stkTxn.TransactionType = 'consumption-items'
				AND itm.ItemType = 'consumables'
				AND (
					CONVERT(DATE, stkTxn.TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					)
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_Consumption'
						) > 0
					)
			
			UNION
			
			-- Table 6 :INVStockManageOut	
			SELECT X.TransactionDate
			FROM (
				SELECT CONVERT(DATE, StkTxn.TransactionDate) AS 'TransactionDate'
				FROM INV_TXN_StockTransaction StkTxn
				JOIN INV_MST_Item itm ON StkTxn.ItemId = itm.ItemId
				JOIN INV_MST_ItemSubCategory sb ON itm.SubCategoryId = sb.SubCategoryId
				WHERE (
						ISNULL(StkTxn.IsTransferredToACC,0) = 0
						)
					AND StkTxn.TransactionType IN (
						'fy-managed-item'
						,'stock-managed-item'
						)
					AND (
						StkTxn.OutQty > 0
						OR StkTxn.InQty > 0
						)
					AND (CONVERT(DATE,StkTxn.TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate))
					--AND itm.ItemType='consumables'
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'INV_StockManageIn'
						OR [Description] = 'INV_StockManageOut'
						) > 0
					)
				) AS X

		END

		IF (@SectionId = 2) -- Billing Section
		BEGIN
			IF (
					(
						SELECT TOP 1 CONVERT(BIT, ParameterValue)
						FROM CORE_CFG_Parameters
						WHERE ParameterGroupName = 'accounting'
							AND ParameterName = 'GetBillingFromSyncTable'
						) = 1
					)
			BEGIN
				SELECT CONVERT(DATE, TransactionDate) AS 'TransactionDate'
				FROM BIL_SYNC_BillingAccounting
				WHERE ISNULL(IsTransferedToAcc,0) = 0
					AND CONVERT(DATE, TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
			END
			ELSE
			BEGIN
				--Cash Bill--
				SELECT CONVERT(DATE, txn.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_BillingTransactionItems itm
					,BIL_TXN_BillingTransaction txn
				WHERE txn.BillingTransactionId = itm.BillingTransactionId
					AND Convert(DATE, txn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND itm.BillingTransactionId IS NOT NULL
					AND (
						txn.PaymentMode = 'cash'
						OR txn.PaymentMode = 'card'
						OR txn.PaymentMode = 'cheque'
						)
					AND ISNULL(itm.IsCashBillSync, 0) = 0
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)

				
				UNION
				
				--Credit Bill--
				SELECT CONVERT(DATE, txn.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_BillingTransactionItems itm
					,BIL_TXN_BillingTransaction txn
				WHERE txn.BillingTransactionId = itm.BillingTransactionId
					AND Convert(DATE, txn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND itm.BillingTransactionId IS NOT NULL
					AND txn.PaymentMode = 'credit'
					AND ISNULL(itm.IsCreditBillSync, 0) = 0
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				
				UNION
				
				--Cash Bill Return--
				SELECT CONVERT(DATE, txn.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_InvoiceReturnItems itm
					,BIL_TXN_InvoiceReturn txn
				WHERE txn.BillReturnId = itm.BillReturnId
					AND Convert(DATE, txn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
							--AND  ( txn.PaymentMode='cash' OR txn.PaymentMode='card' OR txn.PaymentMode='cheque') 
					AND ISNULL(itm.IsCashBillSyncToAcc, 0) = 0
					AND txn.BillStatus = 'paid'
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				
				UNION
				
				--CreditBillReturn--
				SELECT CONVERT(DATE, txn.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_InvoiceReturnItems itm
					,BIL_TXN_InvoiceReturn txn
				WHERE txn.BillReturnId = itm.BillReturnId
					AND CONVERT(DATE, txn.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND txn.BillStatus = 'unpaid'
					AND ISNULL(itm.IsCreditBillSyncToAcc, 0) = 0 -- Include only Not-Synced Data for Credit Return Case--
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				
				UNION
				
				--Deposit Add--
				SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_Deposit
				WHERE CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND TransactionType = 'Deposit'
					AND ISNULL(IsDepositSync, 0) = 0
					AND ModuleName = 'Billing'
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				
				UNION
				
				--Deposit Return/Deduct--
				SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_Deposit
				WHERE CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND TransactionType IN (
						'ReturnDeposit'
						,'depositdeduct'
						)
					AND ISNULL(IsDepositSync, 0) = 0
					AND ModuleName = 'Billing'
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				
				UNION
				
				SELECT CONVERT(DATE, settl.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_Settlements settl
				WHERE CONVERT(DATE, settl.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND ISNULL(settl.IsSyncToAcc, 0) = 0
					AND ISNULL(settl.DiscountReturnAmount, 0) = 0 -- not including discount return case
				    AND ModuleName = 'Billing'
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)

				UNION
				
				SELECT CONVERT(DATE, settl.CreatedOn) AS 'TransactionDate'
				FROM BIL_TXN_Settlements settl
				WHERE CONVERT(DATE, settl.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
						AND CONVERT(DATE, @ToDate)
					AND ISNULL(settl.IsSyncToAcc, 0) = 0
					AND ISNULL(settl.DiscountReturnAmount, 0) != 0 -- only taking discount return case
					AND ModuleName = 'Billing'
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
				UNION

				--Scheme Refund
				SELECT CONVERT(DATE,refund.CreatedOn) As 'TransactionDate'
				FROM BIL_TXN_SchemeRefund refund
				WHERE CONVERT(DATE,refund.CreatedOn) BETWEEN CONVERT(DATE,@FromDate)
				AND CONVERT(DATE,@ToDate)
				AND ISNULL(refund.IsTransferredToAcc,0) = 0
					AND (
						(
							SELECT count([Description])
							FROM @Rules
							WHERE [Description] = 'BIL_Income_Voucher'
							) > 0
						)
			END
		END

		IF (@SectionId = 3) -- Pharmacy Section			
		BEGIN
			--Table1: CashInvoice
			SELECT CONVERT(DATE, inv.CreateOn) AS 'TransactionDate'
			FROM PHRM_TXN_Invoice inv
			WHERE ISNULL(inv.IsTransferredToACC,0) = 0
				AND CONVERT(DATE, inv.CreateOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)	
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_Income_Voucher'
						) > 0
					)

			
			UNION
			
			--Table3: CashInvoiceReturn
			SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
			FROM PHRM_TXN_InvoiceReturn invRet
			WHERE ISNULL(invRet.IsTransferredToACC,0) = 0
				AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_Income_Voucher'
						) > 0
					)

			
			UNION
			
			--Table4: goodsReceipt
			SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
			FROM PHRM_GoodsReceipt gr
			WHERE ISNULL(gr.IsTransferredToACC,0) = 0
				AND gr.IsCancel = 0
				AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_Purchase'
						) > 0
					)
			
			UNION
			
			--Table5: writeoff
			SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
			FROM PHRM_WriteOff wrOff
			WHERE ISNULL(wrOff.IsTransferredToACC,0) = 0
				AND CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_WriteOff'
						) > 0
					)

			UNION
			--Table6: dispatchToDept && dispatchToDeptRet
			SELECT CONVERT(DATE,stockTxn.TransactionDate) AS 'TransactionDate' 
			FROM PHRM_TXN_StockTransaction stockTxn 
			WHERE ISNULL(stockTxn.IsTransferedToAcc,0) = 0 
			AND  CONVERT(DATE, stockTxn.TransactionDate) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate) 
			AND stockTxn.TransactionType IN (
					'dispensary-dispatched-item'
					,'transfer-item','dispatched-item'
			)
			AND (
			(
				SELECT count([Description])
				FROM @Rules
				WHERE [Description] = 'PHRM_ConsumableDispatch'
				OR [Description] = 'PHRM_ConsumableDispatchReturn'
				) > 0
			)
			
			UNION
			
			--Table7 : Settlement 
			SELECT CONVERT(DATE, SettlementDate) AS 'TransactionDate'
			FROM BIL_TXN_Settlements sett
			WHERE ISNULL(sett.IsSyncToAcc, 0) = 0
				AND CONVERT(DATE, SettlementDate) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND ModuleName = 'Dispensary'
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_Income_Voucher'
						) > 0
					)
			
			UNION
			
			--Table7 : Return To Supplier 
			SELECT CONVERT(DATE, ReturnDate) AS 'TransactionDate'
			FROM PHRM_ReturnToSupplier ret
			WHERE ISNULL(ret.IsTransferredToACC, 0) = 0
				AND CONVERT(DATE, ReturnDate) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_PurchaseReturn'
						) > 0
					)
			
			UNION
			
			--Table8 : PHRM Stock Adjustment
			SELECT CONVERT(DATE, TransactionDate) AS 'TransactionDate'
			FROM PHRM_TXN_StockTransaction
			WHERE TransactionType = 'stock-managed-item'
				AND ISNULL(IsTransferedToACC, 0) = 0
				AND CONVERT(DATE, TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_StockManageIn'
						OR [Description] = 'PHRM_StockManageOut'
						) > 0
					)
			
			UNION
			
			--Deposit Add--
			SELECT CONVERT(DATE, CreatedOn) AS 'TransactionDate'
			FROM BIL_TXN_Deposit
			WHERE CONVERT(DATE, CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
				AND TransactionType IN (
					'Deposit'
					,'ReturnDeposit'
					)
				AND ISNULL(IsDepositSync, 0) = 0
				AND ModuleName = 'Pharmacy'
					AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'PHRM_Income_Voucher'
						) > 0
					)
		END

		IF (@SectionId = 5) -- Incetives Section
		BEGIN
			SELECT CONVERT(DATE, TransactionDate) AS 'TransactionDate'
			FROM INCTV_TXN_IncentiveFractionItem outerTbl
			WHERE Convert(DATE, outerTbl.TransactionDate) BETWEEN CONVERT(DATE, @FromDate)
					AND CONVERT(DATE, @ToDate)
				AND ISNULL(IsTransferToAcc, 0) = 0
				AND ISNULL(outerTbl.IsActive, 0) = 1
				AND (
					(
						SELECT count([Description])
						FROM @Rules
						WHERE [Description] = 'ConsultantIncentive'
						) > 0
					)
			GROUP BY Convert(DATE, TransactionDate)
		END
	END
END