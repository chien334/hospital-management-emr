CREATE OR REPLACE FUNCTION sp_acc_bil_getcashinvoicedata(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "BillingAccountingSyncId" INT,
    "ReferenceId" INT,
    "ReferenceModelName" VARCHAR,
    "ServiceDepartmentId" INT,
    "ItemId" INT,
    "PatientId" INT,
    "TransactionType" TIMESTAMP,
    "PaymentMode" VARCHAR,
    "SubTotal" DECIMAL,
    "TaxAmount" DECIMAL,
    "DiscountAmount" INT,
    "CoPaymentCashAmount" DECIMAL,
    "TotalAmount" DECIMAL,
    "IsTransferedToAcc" BOOLEAN,
    "TransactionDate" TIMESTAMP,
    "CreatedOn" TIMESTAMP,
    "CreatedBy" VARCHAR,
    "SettlementDiscountAmount" INT,
    "Remark" VARCHAR,
    "CreditOrganizationId" INT,
    "LedgerId" INT,
    "SubLedgerId" INT
) AS $$
BEGIN
    --change history
    /*
    sn.                auther/timestamp                   description
    1.                 devn/20th march 23                separated from sp_acc_bill_getbillingdataforacctransfer
    2.                 devn/19th may 23                  added subledgerid field in select statement.
    
    */
    -- exec sp_acc_bil_getcashinvoicedata '2023-03-20',3
    
    	RETURN QUERY SELECT billingtransactionitemid AS "BillingAccountingSyncId"
    		,billingtransactionitemid AS "ReferenceId"
    		,'BillingTransactionItem' AS "ReferenceModelName"
    		,servicedepartmentid
    		,serviceitemid AS "ItemId"
    		,itm.patientid
    		,'CashBill' AS "TransactionType"
    		,'cash' AS "PaymentMode"
    		,itm.subtotal
    		,tax AS "TaxAmount"
    		,itm.discountamount
    		,0 AS "CoPaymentCashAmount"
    		,itm.subtotal AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,itm.paiddate AS "TransactionDate"
    		,current_timestamp AS "CreatedOn"
    		,itm.paymentreceivedby AS "CreatedBy"
    		,0 AS "SettlementDiscountAmount"
    		,null AS "Remark"
    		,coalesce(txn.organizationid, 0) AS "CreditOrganizationId"
    		,(
    			select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid)
    			) AS "LedgerId"
    		,(select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid)) AS "SubLedgerId"
    	from bil_txn_billingtransactionitems itm
    		,bil_txn_billingtransaction txn
    	where txn.billingtransactionid = itm.billingtransactionid
    		and (itm.paiddate)::date = p_transactiondate
    		and itm.billingtransactionid is not null
    		and (
    			txn.paymentmode = 'cash'
    			or txn.paymentmode = 'card'
    			or txn.paymentmode = 'cheque'
    			)
    		and coalesce(itm.iscashbillsync, 0) = 0; -- include only not-synced data for cashbill case--
END;
$$ LANGUAGE plpgsql;