CREATE OR REPLACE FUNCTION sp_acc_gettransactiondates(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_hospitalid INT DEFAULT NULL,
    p_sectionid INT DEFAULT NULL
)
RETURNS TABLE (
    transactiondate DATE
) AS $$
BEGIN
    -- Create temp table for rules
    CREATE TEMP TABLE IF NOT EXISTS temp_rules (
        groupmappingid INT,
        description VARCHAR(200),
        transferruleid INT
    );
    TRUNCATE temp_rules;

    INSERT INTO temp_rules (groupmappingid, description, transferruleid)
    SELECT gm.groupmappingid, gm.description, r.transferruleid
    FROM acc_mst_groupmapping gm
    JOIN acc_mst_hospital_transferrules_mapping r ON gm.groupmappingid = r.transferruleid
    WHERE r.isactive = TRUE
    GROUP BY gm.groupmappingid, gm.description, r.transferruleid;

    IF (p_fromdate IS NOT NULL AND p_todate IS NOT NULL AND p_hospitalid IS NOT NULL AND p_sectionid IS NOT NULL) THEN
        IF (p_sectionid = 1) THEN -- Inventory Section
            RETURN QUERY
            -- 1. GoodReceipt
            SELECT gr.goodsreceiptdate::DATE AS transactiondate
            FROM inv_txn_goodsreceipt gr
            WHERE COALESCE(gr.istransferredtoacc, FALSE) = FALSE
              AND (gr.goodsreceiptdate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND COALESCE(gr.iscancel, FALSE) = FALSE
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_Purchase') > 0
            
            UNION
            
            -- 2. WriteOffItems
            SELECT wr.createdon::DATE AS transactiondate
            FROM inv_txn_writeoffitems wr
            WHERE COALESCE(wr.istransferredtoacc, FALSE) = FALSE
              AND (wr.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_WriteOff') > 0
            
            UNION
            
            -- 3. ReturnToVendor
            SELECT rv.createdon::DATE AS transactiondate
            FROM inv_txn_returntovendor rv
            WHERE COALESCE(rv.istransferredtoacc, FALSE) = FALSE
              AND (rv.returndate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_PurchaseReturn') > 0
            
            UNION
            
            -- 4. DispatchToDept
            SELECT stkTxn.transactiondate::DATE AS transactiondate
            FROM inv_txn_stocktransaction stkTxn
            JOIN inv_mst_item itm ON stkTxn.itemid = itm.itemid
            WHERE COALESCE(stkTxn.istransferredtoacc, FALSE) = FALSE
              AND stkTxn.transactiontype IN ('dispatched-item-from', 'returned-item-from')
              AND COALESCE(itm.isfixedassets, FALSE) = FALSE
              AND (stkTxn.transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_ConsumableDispatch' OR description = 'INV_ConsumableDispatchReturn') > 0
            
            UNION
            
            -- 5. INVDeptConsumedGoods
            SELECT stkTxn.transactiondate::DATE AS transactiondate
            FROM inv_txn_stocktransaction stkTxn
            JOIN inv_mst_item itm ON stkTxn.itemid = itm.itemid
            WHERE COALESCE(stkTxn.istransferredtoacc, FALSE) = FALSE
              AND stkTxn.transactiontype = 'consumption-items'
              AND itm.itemtype = 'consumables'
              AND (stkTxn.transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_Consumption') > 0
            
            UNION
            
            -- 6. INVStockManageOut
            SELECT StkTxn.transactiondate::DATE AS transactiondate
            FROM inv_txn_stocktransaction StkTxn
            JOIN inv_mst_item itm ON StkTxn.itemid = itm.itemid
            JOIN inv_mst_itemsubcategory sb ON itm.subcategoryid = sb.subcategoryid
            WHERE COALESCE(StkTxn.istransferredtoacc, FALSE) = FALSE
              AND StkTxn.transactiontype IN ('fy-managed-item', 'stock-managed-item')
              AND (COALESCE(StkTxn.outqty, 0) > 0 OR COALESCE(StkTxn.inqty, 0) > 0)
              AND (StkTxn.transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'INV_StockManageIn' OR description = 'INV_StockManageOut') > 0;

        ELSIF (p_sectionid = 2) THEN -- Billing Section
            IF (COALESCE((SELECT parametervalue::BOOLEAN FROM core_cfg_parameters WHERE parametergroupname = 'accounting' AND parametername = 'GetBillingFromSyncTable' LIMIT 1), FALSE) = TRUE) THEN
                RETURN QUERY
                SELECT transactiondate::DATE
                FROM bil_sync_billingaccounting
                WHERE COALESCE(istransferedtoacc, FALSE) = FALSE
                  AND (transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE);
            ELSE
                RETURN QUERY
                -- 1. Cash Bill
                SELECT txn.createdon::DATE AS transactiondate
                FROM bil_txn_billingtransactionitems itm
                JOIN bil_txn_billingtransaction txn ON txn.billingtransactionid = itm.billingtransactionid
                WHERE (txn.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND (txn.paymentmode = 'cash' OR txn.paymentmode = 'card' OR txn.paymentmode = 'cheque')
                  AND COALESCE(itm.iscashbillsync, FALSE) = FALSE
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 2. Credit Bill
                SELECT txn.createdon::DATE AS transactiondate
                FROM bil_txn_billingtransactionitems itm
                JOIN bil_txn_billingtransaction txn ON txn.billingtransactionid = itm.billingtransactionid
                WHERE (txn.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND txn.paymentmode = 'credit'
                  AND COALESCE(itm.iscreditbillsync, FALSE) = FALSE
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 3. Cash Bill Return
                SELECT txn.createdon::DATE AS transactiondate
                FROM bil_txn_invoicereturnitems itm
                JOIN bil_txn_invoicereturn txn ON txn.billreturnid = itm.billreturnid
                WHERE (txn.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND COALESCE(itm.iscashbillsynctoacc, FALSE) = FALSE
                  AND txn.billstatus = 'paid'
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 4. Credit Bill Return
                SELECT txn.createdon::DATE AS transactiondate
                FROM bil_txn_invoicereturnitems itm
                JOIN bil_txn_invoicereturn txn ON txn.billreturnid = itm.billreturnid
                WHERE (txn.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND txn.billstatus = 'unpaid'
                  AND COALESCE(itm.iscreditbillsynctoacc, FALSE) = FALSE
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 5. Deposit Add
                SELECT createdon::DATE AS transactiondate
                FROM bil_txn_deposit
                WHERE (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND transactiontype = 'Deposit'
                  AND COALESCE(isdepositsync, FALSE) = FALSE
                  AND modulename = 'Billing'
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 6. Deposit Return/Deduct
                SELECT createdon::DATE AS transactiondate
                FROM bil_txn_deposit
                WHERE (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND transactiontype IN ('ReturnDeposit', 'depositdeduct')
                  AND COALESCE(isdepositsync, FALSE) = FALSE
                  AND modulename = 'Billing'
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 7. Settlement
                SELECT settl.createdon::DATE AS transactiondate
                FROM bil_txn_settlements settl
                WHERE (settl.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND COALESCE(settl.issynctoacc, FALSE) = FALSE
                  AND COALESCE(settl.discountreturnamount, 0) = 0
                  AND modulename = 'Billing'
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 8. Discount Return
                SELECT settl.createdon::DATE AS transactiondate
                FROM bil_txn_settlements settl
                WHERE (settl.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND COALESCE(settl.issynctoacc, FALSE) = FALSE
                  AND COALESCE(settl.discountreturnamount, 0) != 0
                  AND modulename = 'Billing'
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0
                
                UNION
                
                -- 9. Scheme Refund
                SELECT refund.createdon::DATE AS transactiondate
                FROM bil_txn_schemerefund refund
                WHERE (refund.createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
                  AND COALESCE(refund.istransferredtoacc, FALSE) = FALSE
                  AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'BIL_Income_Voucher') > 0;
            END IF;

        ELSIF (p_sectionid = 3) THEN -- Pharmacy Section
            RETURN QUERY
            -- 1. CashInvoice
            SELECT inv.createon::DATE AS transactiondate
            FROM phrm_txn_invoice inv
            WHERE COALESCE(inv.istransferredtoacc, FALSE) = FALSE
              AND (inv.createon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_Income_Voucher') > 0
            
            UNION
            
            -- 2. CashInvoiceReturn
            SELECT createdon::DATE AS transactiondate
            FROM phrm_txn_invoicereturn invRet
            WHERE COALESCE(invRet.istransferredtoacc, FALSE) = FALSE
              AND (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_Income_Voucher') > 0
            
            UNION
            
            -- 3. GoodsReceipt
            SELECT createdon::DATE AS transactiondate
            FROM phrm_goodsreceipt gr
            WHERE COALESCE(gr.istransferredtoacc, FALSE) = FALSE
              AND COALESCE(gr.iscancel, FALSE) = FALSE
              AND (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_Purchase') > 0
            
            UNION
            
            -- 4. WriteOff
            SELECT createdon::DATE AS transactiondate
            FROM phrm_writeoff wrOff
            WHERE COALESCE(wrOff.istransferredtoacc, FALSE) = FALSE
              AND (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_WriteOff') > 0
            
            UNION
            
            -- 5. DispatchToDept
            SELECT stockTxn.transactiondate::DATE AS transactiondate
            FROM phrm_txn_stocktransaction stockTxn
            WHERE COALESCE(stockTxn.istransferedtoacc, FALSE) = FALSE
              AND (stockTxn.transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND stockTxn.transactiontype IN ('dispensary-dispatched-item', 'transfer-item', 'dispatched-item')
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_ConsumableDispatch' OR description = 'PHRM_ConsumableDispatchReturn') > 0
            
            UNION
            
            -- 6. Settlement
            SELECT sett.settlementdate::DATE AS transactiondate
            FROM bil_txn_settlements sett
            WHERE COALESCE(sett.issynctoacc, FALSE) = FALSE
              AND (sett.settlementdate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND modulename = 'Dispensary'
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_Income_Voucher') > 0
            
            UNION
            
            -- 7. Return To Supplier
            SELECT ret.returndate::DATE AS transactiondate
            FROM phrm_returntosupplier ret
            WHERE COALESCE(ret.istransferredtoacc, FALSE) = FALSE
              AND (ret.returndate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_PurchaseReturn') > 0
            
            UNION
            
            -- 8. PHRM Stock Adjustment
            SELECT transactiondate::DATE AS transactiondate
            FROM phrm_txn_stocktransaction
            WHERE transactiontype = 'stock-managed-item'
              AND COALESCE(istransferedtoacc, FALSE) = FALSE
              AND (transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_StockManageIn' OR description = 'PHRM_StockManageOut') > 0
            
            UNION
            
            -- 9. Deposit Add
            SELECT createdon::DATE AS transactiondate
            FROM bil_txn_deposit
            WHERE (createdon::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND transactiontype IN ('Deposit', 'ReturnDeposit')
              AND COALESCE(isdepositsync, FALSE) = FALSE
              AND modulename = 'Pharmacy'
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'PHRM_Income_Voucher') > 0;

        ELSIF (p_sectionid = 5) THEN -- Incentives Section
            RETURN QUERY
            SELECT outerTbl.transactiondate::DATE AS transactiondate
            FROM inctv_txn_incentivefractionitem outerTbl
            WHERE (outerTbl.transactiondate::DATE BETWEEN p_fromdate::DATE AND p_todate::DATE)
              AND COALESCE(outerTbl.istransfertoacc, FALSE) = FALSE
              AND COALESCE(outerTbl.isactive, FALSE) = TRUE
              AND (SELECT COUNT(*) FROM temp_rules WHERE description = 'ConsultantIncentive') > 0
            GROUP BY outerTbl.transactiondate::DATE;
        END IF;
    END IF;

    -- Drop temp table
    DROP TABLE temp_rules;
END;
$$ LANGUAGE plpgsql;
