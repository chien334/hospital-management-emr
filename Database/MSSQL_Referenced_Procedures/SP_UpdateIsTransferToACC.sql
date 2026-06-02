CREATE PROCEDURE [dbo].[SP_UpdateIsTransferToACC] @ReferenceIds VARCHAR(max)
	,@TransactionType NVARCHAR(50)
	,@IsReverseTransaction BIT = 0
	,@TransactionDate VARCHAR(30) = NULL
	,@ReferenceIdsOne VARCHAR(max)
AS
/*
FileName: [SP_UpdateIsTransferToACC]
Author  : Salakha/NageshBB
Created date: 25 Feb 2019
Description: Created Script to Update column IsTransferToACC
			This work in two scenario 1-when transferred records into accounting, 2-Undo transaction (datewise) from accounting		
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Salakha/NageshBB /25Feb 2020		  Created Script to Update column IsTransferToACC
2		NageshBB/12Aug 2020		              Changes for Inventory module transaction where
											  Transaction type INVDeptConsumedGoods get records from WARD_INV_Consumption table 
											  and INVDispatchToDept get records from INV_TXN_StockTransaction				
											  Now both transaction type get records from single table i.e.WARD_INV_Transaction
											  done changes for this update column value IsTransferToAcc
3		NageshBB/20Aug 2020					 Inventory Transaction Type INVStockManageOut need to handle for reverse txn and Update after transfer records
											 This transaction from 2 table 
4       NageshBB/Sanjit sir /12July2021      updated invoice return for pharmacy module 
5       NageshBB/Sanjit sir /13July2021      updated invoice return for inventory module
6		Bikash 31Jan2022					 Added Credit bill paid (i.e. Settlement) status flag 'IsSyncToAcc' and this will also handels discount return case.
7.		Bikash 14thMarch2022				changes in DiscountReturn and DepositDeduct transaction type
8.      Dev Narayan 27thMay2022              Added status flag 'IsTransferredToACC' for Pharmacy Settlement,Deposit, And Stock Adjustment.
9.      Dev Narayan 6th June 2022            Change for Inventory integration
10.     DevN/21th May 23                     Change Update Column Values into NULL to 0.
11.     DevN/25th, June 23                   SP update with new TransactionTypes and DataSources..
12.     DevN/7th, Aug 23'                    Update IsTransferredToAccounting Flag for billing settlement.
13.     DevN/15th, Oct 23'                   Update status for Inventory Comsumption.
*/
BEGIN
	IF (@IsReverseTransaction = 0) -- when transferred record to accounting
	BEGIN

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'PHRM_UserWiseNetCollection')
		BEGIN
			EXECUTE ('UPDATE PHRM_EmployeeCashTransaction SET IsTransferredToAcc = 1 WHERE CashTxnId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_CASH_Sales' OR @TransactionType='PHRM_OPD_CREDIT_Sales'
			OR @TransactionType='PHRM_Discount' OR @TransactionType ='PHRM_IPD_CASH_Sales' OR @TransactionType='PHRM_IPD_CREDIT_Sales' 
			OR @TransactionType='PHRM_Credit_Sale'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_Invoice SET IsTransferredToACC = 1 WHERE InvoiceId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_CASH_Sales_Return'
			OR @TransactionType='PHRM_OPD_CREDIT_Sales_Return' OR @TransactionType='PHRM_Discount_Return'
			OR @TransactionType='PHRM_IPD_CASH_Sales_Return' OR @TransactionType='PHRM_IPD_CREDIT_Sales_Return'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_InvoiceReturn SET IsTransferredToACC = 1 WHERE InvoiceReturnId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_GoodReceipt_Supplier'
			OR @TransactionType='PHRM_GoodReceipt_Purchase' OR @TransactionType='PHRM_GoodReceipt_VAT'))
		BEGIN
			EXECUTE ('UPDATE PHRM_GoodsReceipt SET IsTransferredToACC = 1 WHERE GoodReceiptId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_GoodReceiptReturn_Supplier' OR @TransactionType='PHRM_GoodReceiptReturn_Purchase'
			OR @TransactionType='PHRM_GoodReceiptReturn_VAT'))
		BEGIN
			EXECUTE ('UPDATE PHRM_ReturnToSupplier SET IsTransferredToACC = 1 WHERE ReturnToSupplierId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_DepositAdjustment'
			OR @TransactionType='PHRM_IPD_DepositAdjustment'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_Settlement' OR @TransactionType='PHRM_Settlement_Discount'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 1 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_ConsumableDispatch_MainStore' OR @TransactionType='PHRM_ConsumableDispatch_SubStore'
			OR @TransactionType='PHRM_ConsumableDispatchReturn_MainStore' OR @TransactionType='PHRM_ConsumableDispatchReturn_SubStore' OR @TransactionType='PHRM_StockManageItem'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_StockTransaction SET IsTransferedToAcc = 1 WHERE StockTransactionId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_WriteOffItems'))
		BEGIN
			EXECUTE ('UPDATE PHRM_WriteOff SET IsTransferredToACC = 1 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_GoodReceipt_Vendor'OR @TransactionType='INV_GoodReceipt_Purchase'
			OR @TransactionType='INV_GoodReceipt_VAT'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_GoodsReceipt SET IsTransferredToACC = 1 WHERE GoodsReceiptID IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'INVWriteOff')
		BEGIN
			EXECUTE ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 1 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_GoodReceiptReturn_Vendor' OR @TransactionType='INV_GoodReceiptReturn_Purchase'
			OR @TransactionType='INV_GoodReceiptReturn_VAT'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_ReturnToVendor SET IsTransferredToAcc = 1 WHERE ReturnToVendorId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_ConsumableDispatch_SubStore' OR @TransactionType='INV_ConsumableDispatch_CentralStore'
			OR @TransactionType='INV_ConsumableDispatchReturn_SubStore' OR @TransactionType='INV_ConsumableDispatchReturn_CentralStore'
			OR @TransactionType='INV_StockManageItem' OR @TransactionType='INV_Consumption_CentralStore' OR @TransactionType='INV_Consumption_SubStore'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_StockTransaction SET IsTransferredToACC = 1 WHERE StockTransactionId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'INV_WriteOffItems')
		BEGIN
			EXECUTE ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 1 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END

		--IF (@ReferenceIds IS NOT NULL
		--  AND @TransactionType = 'BillingRecords')
		--BEGIN
		--  EXECUTE ('UPDATE BIL_SYNC_BillingAccounting SET IsTransferedToAcc = 1 WHERE BillingAccountingSyncId IN (' + @ReferenceIds + ')')
		--END
		-- 1
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_OPD_Sales' OR @TransactionType = 'BIL_IPD_Sales'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 1,IsCreditBillSync = 1 WHERE BillingTransactionItemId IN (' + @ReferenceIds + ')')
		END

		-- 2
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_Credit_Sale')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_BillingTransactionItems SET IsCreditBillSync = 1,IsCashBillSync = 1 WHERE BillingTransactionItemId IN (' + @ReferenceIds + ')')
		END

		-- 3
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_Settlement' OR @TransactionType = 'BIL_Settlement_Discount'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 1 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		-- 4
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_OPD_SaleReturn' OR @TransactionType ='BIL_IPD_SaleReturn'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 1,IsCreditBillSyncToAcc = 1 WHERE BillReturnItemId IN (' + @ReferenceIds + ')')
		END

		-- 5
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_Credit_SaleReturn')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 1,IsCreditBillSyncToAcc = 1 WHERE BillReturnItemId IN (' + @ReferenceIds + ')')
		END

		IF(@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_UserWiseNetCollection')
		BEGIN
			EXECUTE('UPDATE TXN_EmpCashTransaction SET IsTransferredToAcc = 1 WHERE CashTxnId IN(' + @ReferenceIds + ')')
		END

		-- 6
		IF (
				@ReferenceIds IS NOT NULL AND @TransactionType IN (
					'BIL_OPD_Deposit'
					,'BIL_OPD_DepositAdjustment'
					,'BIL_IPD_Deposit'
					,'BIL_IPD_DepositAdjustment'
					)
				)
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' + @ReferenceIds + ')')
		END

		--IF (@ReferenceIds IS NOT NULL
		--AND @TransactionType = 'DepositReturn')
		--BEGIN
		--EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' + @ReferenceIds + ')')
		--END	
		-- 8
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'CashDiscount')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsCashDiscountSync = 1 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'Scheme_Refund')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_SchemeRefund SET IsTransferredToAcc = 1 WHERE SchemeRefundId IN (' + @ReferenceIds + ')')
		END
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'ConsultantIncentive')
		BEGIN
			EXECUTE ('UPDATE INCTV_TXN_IncentiveFractionItem SET IsTransferToAcc = 1 WHERE InctvTxnItemId IN (' + @ReferenceIds + ')')
		END
	END
	ELSE -- IF ReverseTransaction is true, update IsTransferredToACC is null, undo transaction done by super admin
	BEGIN
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'PHRM_UserWiseNetCollection')
		BEGIN
			EXECUTE ('UPDATE PHRM_EmployeeCashTransaction SET IsTransferredToAcc = 0 WHERE CashTxnId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_CASH_Sales' OR @TransactionType='PHRM_OPD_CREDIT_Sales'
			OR @TransactionType='PHRM_Discount' OR @TransactionType ='PHRM_IPD_CASH_Sales' OR @TransactionType='PHRM_IPD_CREDIT_Sales' 
			OR @TransactionType='PHRM_Credit_Sale'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_Invoice SET IsTransferredToACC = 0 WHERE InvoiceId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_CASH_Sales_Return'
			OR @TransactionType='PHRM_OPD_CREDIT_Sales_Return' OR @TransactionType='PHRM_Discount_Return'
			OR @TransactionType='PHRM_IPD_CASH_Sales_Return' OR @TransactionType='PHRM_IPD_CREDIT_Sales_Return'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_InvoiceReturn SET IsTransferredToACC = 0 WHERE InvoiceReturnId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_GoodReceipt_Supplier'
			OR @TransactionType='PHRM_GoodReceipt_Purchase' OR @TransactionType='PHRM_GoodReceipt_VAT'))
		BEGIN
			EXECUTE ('UPDATE PHRM_GoodsReceipt SET IsTransferredToACC = 0 WHERE GoodReceiptId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_GoodReceiptReturn_Supplier' OR @TransactionType='PHRM_GoodReceiptReturn_Purchase'
			OR @TransactionType='PHRM_GoodReceiptReturn_VAT'))
		BEGIN
			EXECUTE ('UPDATE PHRM_ReturnToSupplier SET IsTransferredToACC = 0 WHERE ReturnToSupplierId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_OPD_DepositAdjustment'
			OR @TransactionType='PHRM_IPD_DepositAdjustment'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 0 WHERE DepositId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_Settlement' OR @TransactionType='PHRM_Settlement_Discount'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 0 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_ConsumableDispatch_MainStore' OR @TransactionType='PHRM_ConsumableDispatch_SubStore'
			OR @TransactionType='PHRM_ConsumableDispatchReturn_MainStore' OR @TransactionType='PHRM_ConsumableDispatchReturn_SubStore' OR @TransactionType='PHRM_StockManageItem'))
		BEGIN
			EXECUTE ('UPDATE PHRM_TXN_StockTransaction SET IsTransferedToAcc = 0 WHERE StockTransactionId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'PHRM_WriteOffItems'))
		BEGIN
			EXECUTE ('UPDATE PHRM_WriteOff SET IsTransferredToACC = 0 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_GoodReceipt_Vendor'OR @TransactionType='INV_GoodReceipt_Purchase'
			OR @TransactionType='INV_GoodReceipt_VAT'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_GoodsReceipt SET IsTransferredToACC = 0 WHERE GoodsReceiptID IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'INVWriteOff')
		BEGIN
			EXECUTE ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 0 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_GoodReceiptReturn_Vendor' OR @TransactionType='INV_GoodReceiptReturn_Purchase'
			OR @TransactionType='INV_GoodReceiptReturn_VAT'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_ReturnToVendor SET IsTransferredToAcc = 0 WHERE ReturnToVendorId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'INV_ConsumableDispatch_SubStore' OR @TransactionType='INV_ConsumableDispatch_CentralStore'
			OR @TransactionType='INV_ConsumableDispatchReturn_SubStore' OR @TransactionType='INV_ConsumableDispatchReturn_CentralStore'
			OR @TransactionType='INV_StockManageItem' OR @TransactionType='INV_Consumption_CentralStore' OR @TransactionType='INV_Consumption_SubStore'))
		BEGIN
			EXECUTE ('UPDATE INV_TXN_StockTransaction SET IsTransferredToACC = 0 WHERE StockTransactionId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'INV_WriteOffItems')
		BEGIN
			EXECUTE ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 0 WHERE WriteOffId IN (' + @ReferenceIds + ')')
		END

		--IF (@ReferenceIds IS NOT NULL
		--  AND @TransactionType = 'BillingRecords' AND @TransactionDate is not null)
		--BEGIN
		--  EXECUTE ('UPDATE BIL_SYNC_BillingAccounting SET IsTransferedToAcc = NULL WHERE ReferenceId IN (' + @ReferenceIds + ') and  convert(date,TransactionDate) = convert(date,'+''''+ @TransactionDate +''''+')') 
		--END
		-- 1
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_OPD_Sales' OR @TransactionType = 'BIL_IPD_Sales'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 0,IsCreditBillSync = 0 WHERE BillingTransactionItemId IN (' + @ReferenceIds + ')')
		END

		-- 2
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_Credit_Sale')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 0,IsCreditBillSync = 0 WHERE BillingTransactionItemId IN (' + @ReferenceIds + ')')
		END

		-- 3
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_Settlement' OR @TransactionType = 'BIL_Settlement_Discount'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 0 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		-- 4
		IF (@ReferenceIds IS NOT NULL AND (@TransactionType = 'BIL_OPD_SaleReturn'OR @TransactionType ='BIL_IPD_SaleReturn'))
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 0,IsCreditBillSyncToAcc = 0 WHERE BillReturnItemId IN (' + @ReferenceIds + ')')
		END

		-- 5
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_Credit_SaleReturn')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 0,IsCreditBillSyncToAcc = 0 WHERE BillReturnItemId IN (' + @ReferenceIds + ')')
		END

		IF(@ReferenceIds IS NOT NULL AND @TransactionType = 'BIL_UserWiseNetCollection')
		BEGIN
			EXECUTE('UPDATE TXN_EmpCashTransaction SET IsTransferredToAcc = 0 WHERE CashTxnId IN(' + @ReferenceIds + ')')
		END

		-- 6
		IF (
				@ReferenceIds IS NOT NULL AND @TransactionType IN (
					'BIL_OPD_Deposit'
					,'BIL_OPD_DepositAdjustment'
					,'BIL_IPD_Deposit'
					,'BIL_IPD_DepositAdjustment'
					)
				)
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 0 WHERE DepositId IN (' + @ReferenceIds + ')')
		END

		--IF (@ReferenceIds IS NOT NULL
		--AND @TransactionType = 'DepositReturn')
		--BEGIN
		--EXECUTE ('UPDATE BIL_TXN_Deposit SET IsDepositSync = NULL WHERE DepositId IN (' + @ReferenceIds + ')')
		--END	
		-- 8
		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'CashDiscount')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_Settlements SET IsCashDiscountSync = 0 WHERE SettlementId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'Scheme_Refund')
		BEGIN
			EXECUTE ('UPDATE BIL_TXN_SchemeRefund SET IsTransferredToAcc = 0 WHERE SchemeRefundId IN (' + @ReferenceIds + ')')
		END

		IF (@ReferenceIds IS NOT NULL AND @TransactionType = 'ConsultantIncentive')
		BEGIN
			EXECUTE ('UPDATE INCTV_TXN_IncentiveFractionItem SET IsTransferToAcc = 0 WHERE InctvTxnItemId IN (' + @ReferenceIds + ')')
		END
	END
END