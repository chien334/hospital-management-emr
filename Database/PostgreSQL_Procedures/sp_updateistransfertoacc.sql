CREATE OR REPLACE FUNCTION sp_updateistransfertoacc(
    p_referenceids VARCHAR,
    p_transactiontype VARCHAR,
    p_isreversetransaction BOOLEAN DEFAULT FALSE,
    p_transactiondate VARCHAR DEFAULT NULL,
    p_referenceidsone VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    /*
    filename: "sp_updateistransfertoacc"
    author  : salakha/nageshbb
    created date: 25 feb 2019
    description: created script to update column istransfertoacc
    			this work in two scenario 1-when transferred records into accounting, 2-undo transaction (datewise) from accounting		
    change history
    s.no.    updatedby/date                        remarks
    1       salakha/nageshbb /25feb 2020		  created script to update column istransfertoacc
    2		nageshbb/12aug 2020		              changes for inventory module transaction where
    											  transaction type invdeptconsumedgoods get records from ward_inv_consumption table 
    											  and invdispatchtodept get records from inv_txn_stocktransaction				
    											  now both transaction type get records from single table i.e.ward_inv_transaction
    											  done changes for this update column value istransfertoacc
    3		nageshbb/20aug 2020					 inventory transaction type invstockmanageout need to handle for reverse txn and update after transfer records
    											 this transaction from 2 table 
    4       nageshbb/sanjit sir /12july2021      updated invoice return for pharmacy module 
    5       nageshbb/sanjit sir /13july2021      updated invoice return for inventory module
    6		bikash 31jan2022					 added credit bill paid (i.e. settlement) status flag 'IsSyncToAcc' and this will also handels discount return case.
    7.		bikash 14thmarch2022				changes in discountreturn and depositdeduct transaction type
    8.      dev narayan 27thmay2022              added status flag 'IsTransferredToACC' for pharmacy settlement,deposit, and stock adjustment.
    9.      dev narayan 6th june 2022            change for inventory integration
    10.     devn/21th may 23                     change update column values into null to 0.
    11.     devn/25th, june 23                   sp update with new transactiontypes and datasources..
    12.     devn/7th, aug 23'                    Update IsTransferredToAccounting Flag for billing settlement.
    13.     DevN/15th, Oct 23'                   update status for inventory comsumption.
    */
    begin
    	if (p_isreversetransaction = false) -- when transferred record to accounting
    	then
    
    		if (p_referenceids is not null and p_transactiontype = 'PHRM_UserWiseNetCollection')
    		then
    			execute ('UPDATE PHRM_EmployeeCashTransaction SET IsTransferredToAcc = 1 WHERE CashTxnId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_CASH_Sales' or p_transactiontype='PHRM_OPD_CREDIT_Sales'
    			or p_transactiontype='PHRM_Discount' or p_transactiontype ='PHRM_IPD_CASH_Sales' or p_transactiontype='PHRM_IPD_CREDIT_Sales' 
    			or p_transactiontype='PHRM_Credit_Sale'))
    		then
    			execute ('UPDATE PHRM_TXN_Invoice SET IsTransferredToACC = 1 WHERE InvoiceId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_CASH_Sales_Return'
    			or p_transactiontype='PHRM_OPD_CREDIT_Sales_Return' or p_transactiontype='PHRM_Discount_Return'
    			or p_transactiontype='PHRM_IPD_CASH_Sales_Return' or p_transactiontype='PHRM_IPD_CREDIT_Sales_Return'))
    		then
    			execute ('UPDATE PHRM_TXN_InvoiceReturn SET IsTransferredToACC = 1 WHERE InvoiceReturnId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_GoodReceipt_Supplier'
    			or p_transactiontype='PHRM_GoodReceipt_Purchase' or p_transactiontype='PHRM_GoodReceipt_VAT'))
    		then
    			execute ('UPDATE PHRM_GoodsReceipt SET IsTransferredToACC = 1 WHERE GoodReceiptId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_GoodReceiptReturn_Supplier' or p_transactiontype='PHRM_GoodReceiptReturn_Purchase'
    			or p_transactiontype='PHRM_GoodReceiptReturn_VAT'))
    		then
    			execute ('UPDATE PHRM_ReturnToSupplier SET IsTransferredToACC = 1 WHERE ReturnToSupplierId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_DepositAdjustment'
    			or p_transactiontype='PHRM_IPD_DepositAdjustment'))
    		then
    			execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_Settlement' or p_transactiontype='PHRM_Settlement_Discount'))
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 1 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_ConsumableDispatch_MainStore' or p_transactiontype='PHRM_ConsumableDispatch_SubStore'
    			or p_transactiontype='PHRM_ConsumableDispatchReturn_MainStore' or p_transactiontype='PHRM_ConsumableDispatchReturn_SubStore' or p_transactiontype='PHRM_StockManageItem'))
    		then
    			execute ('UPDATE PHRM_TXN_StockTransaction SET IsTransferedToAcc = 1 WHERE StockTransactionId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_WriteOffItems'))
    		then
    			execute ('UPDATE PHRM_WriteOff SET IsTransferredToACC = 1 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    		if (p_referenceids is not null and (p_transactiontype = 'INV_GoodReceipt_Vendor'or p_transactiontype='INV_GoodReceipt_Purchase'
    			or p_transactiontype='INV_GoodReceipt_VAT'))
    		then
    			execute ('UPDATE INV_TXN_GoodsReceipt SET IsTransferredToACC = 1 WHERE GoodsReceiptID IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'INVWriteOff')
    		then
    			execute ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 1 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'INV_GoodReceiptReturn_Vendor' or p_transactiontype='INV_GoodReceiptReturn_Purchase'
    			or p_transactiontype='INV_GoodReceiptReturn_VAT'))
    		then
    			execute ('UPDATE INV_TXN_ReturnToVendor SET IsTransferredToAcc = 1 WHERE ReturnToVendorId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'INV_ConsumableDispatch_SubStore' or p_transactiontype='INV_ConsumableDispatch_CentralStore'
    			or p_transactiontype='INV_ConsumableDispatchReturn_SubStore' or p_transactiontype='INV_ConsumableDispatchReturn_CentralStore'
    			or p_transactiontype='INV_StockManageItem' or p_transactiontype='INV_Consumption_CentralStore' or p_transactiontype='INV_Consumption_SubStore'))
    		then
    			execute ('UPDATE INV_TXN_StockTransaction SET IsTransferredToACC = 1 WHERE StockTransactionId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'INV_WriteOffItems')
    		then
    			execute ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 1 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    
    		--if (p_referenceids is not null
    		--  and p_transactiontype = 'BillingRecords')
    		--begin
    		--  execute ('UPDATE BIL_SYNC_BillingAccounting SET IsTransferedToAcc = 1 WHERE BillingAccountingSyncId IN (' + p_referenceids + ')')
    		--end
    		-- 1
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_OPD_Sales' or p_transactiontype = 'BIL_IPD_Sales'))
    		then
    			execute ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 1,IsCreditBillSync = 1 WHERE BillingTransactionItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 2
    		if (p_referenceids is not null and p_transactiontype = 'BIL_Credit_Sale')
    		then
    			execute ('UPDATE BIL_TXN_BillingTransactionItems SET IsCreditBillSync = 1,IsCashBillSync = 1 WHERE BillingTransactionItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 3
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_Settlement' or p_transactiontype = 'BIL_Settlement_Discount'))
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 1 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 4
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_OPD_SaleReturn' or p_transactiontype ='BIL_IPD_SaleReturn'))
    		then
    			execute ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 1,IsCreditBillSyncToAcc = 1 WHERE BillReturnItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 5
    		if (p_referenceids is not null and p_transactiontype = 'BIL_Credit_SaleReturn')
    		then
    			execute ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 1,IsCreditBillSyncToAcc = 1 WHERE BillReturnItemId IN (' || p_referenceids || ')');
    		end if;
    
    		if(p_referenceids is not null and p_transactiontype = 'BIL_UserWiseNetCollection')
    		then
    			execute('UPDATE TXN_EmpCashTransaction SET IsTransferredToAcc = 1 WHERE CashTxnId IN(' || p_referenceids || ')');
    		end if;
    
    		-- 6
    		if (
    				p_referenceids is not null and p_transactiontype in (
    					'BIL_OPD_Deposit'
    					,'BIL_OPD_DepositAdjustment'
    					,'BIL_IPD_Deposit'
    					,'BIL_IPD_DepositAdjustment'
    					)
    				)
    		then
    			execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' || p_referenceids || ')');
    		end if;
    
    		--if (p_referenceids is not null
    		--and p_transactiontype = 'DepositReturn')
    		--begin
    		--execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 1 WHERE DepositId IN (' + p_referenceids + ')')
    		--end	
    		-- 8
    		if (p_referenceids is not null and p_transactiontype = 'CashDiscount')
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsCashDiscountSync = 1 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'Scheme_Refund')
    		then
    			execute ('UPDATE BIL_TXN_SchemeRefund SET IsTransferredToAcc = 1 WHERE SchemeRefundId IN (' || p_referenceids || ')');
    		end if;
    		if (p_referenceids is not null and p_transactiontype = 'ConsultantIncentive')
    		then
    			execute ('UPDATE INCTV_TXN_IncentiveFractionItem SET IsTransferToAcc = 1 WHERE InctvTxnItemId IN (' || p_referenceids || ')');
    		end if;
    	
    	else -- if reversetransaction is true, update istransferredtoacc is null, undo transaction done by super admin
    	
    		if (p_referenceids is not null and p_transactiontype = 'PHRM_UserWiseNetCollection')
    		then
    			execute ('UPDATE PHRM_EmployeeCashTransaction SET IsTransferredToAcc = 0 WHERE CashTxnId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_CASH_Sales' or p_transactiontype='PHRM_OPD_CREDIT_Sales'
    			or p_transactiontype='PHRM_Discount' or p_transactiontype ='PHRM_IPD_CASH_Sales' or p_transactiontype='PHRM_IPD_CREDIT_Sales' 
    			or p_transactiontype='PHRM_Credit_Sale'))
    		then
    			execute ('UPDATE PHRM_TXN_Invoice SET IsTransferredToACC = 0 WHERE InvoiceId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_CASH_Sales_Return'
    			or p_transactiontype='PHRM_OPD_CREDIT_Sales_Return' or p_transactiontype='PHRM_Discount_Return'
    			or p_transactiontype='PHRM_IPD_CASH_Sales_Return' or p_transactiontype='PHRM_IPD_CREDIT_Sales_Return'))
    		then
    			execute ('UPDATE PHRM_TXN_InvoiceReturn SET IsTransferredToACC = 0 WHERE InvoiceReturnId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_GoodReceipt_Supplier'
    			or p_transactiontype='PHRM_GoodReceipt_Purchase' or p_transactiontype='PHRM_GoodReceipt_VAT'))
    		then
    			execute ('UPDATE PHRM_GoodsReceipt SET IsTransferredToACC = 0 WHERE GoodReceiptId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_GoodReceiptReturn_Supplier' or p_transactiontype='PHRM_GoodReceiptReturn_Purchase'
    			or p_transactiontype='PHRM_GoodReceiptReturn_VAT'))
    		then
    			execute ('UPDATE PHRM_ReturnToSupplier SET IsTransferredToACC = 0 WHERE ReturnToSupplierId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_OPD_DepositAdjustment'
    			or p_transactiontype='PHRM_IPD_DepositAdjustment'))
    		then
    			execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 0 WHERE DepositId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_Settlement' or p_transactiontype='PHRM_Settlement_Discount'))
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 0 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_ConsumableDispatch_MainStore' or p_transactiontype='PHRM_ConsumableDispatch_SubStore'
    			or p_transactiontype='PHRM_ConsumableDispatchReturn_MainStore' or p_transactiontype='PHRM_ConsumableDispatchReturn_SubStore' or p_transactiontype='PHRM_StockManageItem'))
    		then
    			execute ('UPDATE PHRM_TXN_StockTransaction SET IsTransferedToAcc = 0 WHERE StockTransactionId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'PHRM_WriteOffItems'))
    		then
    			execute ('UPDATE PHRM_WriteOff SET IsTransferredToACC = 0 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    		if (p_referenceids is not null and (p_transactiontype = 'INV_GoodReceipt_Vendor'or p_transactiontype='INV_GoodReceipt_Purchase'
    			or p_transactiontype='INV_GoodReceipt_VAT'))
    		then
    			execute ('UPDATE INV_TXN_GoodsReceipt SET IsTransferredToACC = 0 WHERE GoodsReceiptID IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'INVWriteOff')
    		then
    			execute ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 0 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'INV_GoodReceiptReturn_Vendor' or p_transactiontype='INV_GoodReceiptReturn_Purchase'
    			or p_transactiontype='INV_GoodReceiptReturn_VAT'))
    		then
    			execute ('UPDATE INV_TXN_ReturnToVendor SET IsTransferredToAcc = 0 WHERE ReturnToVendorId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and (p_transactiontype = 'INV_ConsumableDispatch_SubStore' or p_transactiontype='INV_ConsumableDispatch_CentralStore'
    			or p_transactiontype='INV_ConsumableDispatchReturn_SubStore' or p_transactiontype='INV_ConsumableDispatchReturn_CentralStore'
    			or p_transactiontype='INV_StockManageItem' or p_transactiontype='INV_Consumption_CentralStore' or p_transactiontype='INV_Consumption_SubStore'))
    		then
    			execute ('UPDATE INV_TXN_StockTransaction SET IsTransferredToACC = 0 WHERE StockTransactionId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'INV_WriteOffItems')
    		then
    			execute ('UPDATE INV_TXN_WriteOffItems SET IsTransferredToACC = 0 WHERE WriteOffId IN (' || p_referenceids || ')');
    		end if;
    
    		--if (p_referenceids is not null
    		--  and p_transactiontype = 'BillingRecords' and p_transactiondate is not null)
    		--begin
    		--  execute ('UPDATE BIL_SYNC_BillingAccounting SET IsTransferedToAcc = NULL WHERE ReferenceId IN (' + p_referenceids + ') and  convert(date,TransactionDate) = convert(date,'+''''+ p_transactiondate +''''+')') 
    		--end
    		-- 1
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_OPD_Sales' or p_transactiontype = 'BIL_IPD_Sales'))
    		then
    			execute ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 0,IsCreditBillSync = 0 WHERE BillingTransactionItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 2
    		if (p_referenceids is not null and p_transactiontype = 'BIL_Credit_Sale')
    		then
    			execute ('UPDATE BIL_TXN_BillingTransactionItems SET IsCashBillSync = 0,IsCreditBillSync = 0 WHERE BillingTransactionItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 3
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_Settlement' or p_transactiontype = 'BIL_Settlement_Discount'))
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsSyncToAcc = 0 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 4
    		if (p_referenceids is not null and (p_transactiontype = 'BIL_OPD_SaleReturn'or p_transactiontype ='BIL_IPD_SaleReturn'))
    		then
    			execute ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 0,IsCreditBillSyncToAcc = 0 WHERE BillReturnItemId IN (' || p_referenceids || ')');
    		end if;
    
    		-- 5
    		if (p_referenceids is not null and p_transactiontype = 'BIL_Credit_SaleReturn')
    		then
    			execute ('UPDATE BIL_TXN_InvoiceReturnItems SET IsCashBillSyncToAcc = 0,IsCreditBillSyncToAcc = 0 WHERE BillReturnItemId IN (' || p_referenceids || ')');
    		end if;
    
    		if(p_referenceids is not null and p_transactiontype = 'BIL_UserWiseNetCollection')
    		then
    			execute('UPDATE TXN_EmpCashTransaction SET IsTransferredToAcc = 0 WHERE CashTxnId IN(' || p_referenceids || ')');
    		end if;
    
    		-- 6
    		if (
    				p_referenceids is not null and p_transactiontype in (
    					'BIL_OPD_Deposit'
    					,'BIL_OPD_DepositAdjustment'
    					,'BIL_IPD_Deposit'
    					,'BIL_IPD_DepositAdjustment'
    					)
    				)
    		then
    			execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = 0 WHERE DepositId IN (' || p_referenceids || ')');
    		end if;
    
    		--if (p_referenceids is not null
    		--and p_transactiontype = 'DepositReturn')
    		--begin
    		--execute ('UPDATE BIL_TXN_Deposit SET IsDepositSync = NULL WHERE DepositId IN (' + p_referenceids + ')')
    		--end	
    		-- 8
    		if (p_referenceids is not null and p_transactiontype = 'CashDiscount')
    		then
    			execute ('UPDATE BIL_TXN_Settlements SET IsCashDiscountSync = 0 WHERE SettlementId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'Scheme_Refund')
    		then
    			execute ('UPDATE BIL_TXN_SchemeRefund SET IsTransferredToAcc = 0 WHERE SchemeRefundId IN (' || p_referenceids || ')');
    		end if;
    
    		if (p_referenceids is not null and p_transactiontype = 'ConsultantIncentive')
    		then
    			execute ('UPDATE INCTV_TXN_IncentiveFractionItem SET IsTransferToAcc = 0 WHERE InctvTxnItemId IN (' || p_referenceids || ')');
    		end if;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;