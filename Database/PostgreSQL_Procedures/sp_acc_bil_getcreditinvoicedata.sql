CREATE OR REPLACE FUNCTION sp_acc_bil_getcreditinvoicedata(
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
    -- exec sp_acc_bil_getcreditinvoicedata '2023-05-07',1
    
    	RETURN QUERY SELECT billingtransactionitemid AS "BillingAccountingSyncId"
    		,billingtransactionitemid AS "ReferenceId"
    		,'BillingTransactionItem' AS "ReferenceModelName"
    		,servicedepartmentid
    		,serviceitemid AS "ItemId"
    		,itm.patientid
    		,'CreditBill' AS "TransactionType"
    		,txn.paymentmode AS "PaymentMode"
    		,itm.subtotal
    		,tax AS "TaxAmount"
    		,itm.discountamount
    		,coalesce(itm.copaymentcashamount, 0) AS "CoPaymentCashAmount"
    		,itm.subtotal AS "TotalAmount"
    		,0 AS "IsTransferedToAcc"
    		,txn.createdon AS "TransactionDate"
    		,-- this is credit date.. 
    		current_timestamp AS "CreatedOn"
    		,itm.createdby AS "CreatedBy"
    		,0 AS "SettlementDiscountAmount"
    		,null AS "Remark"
    		,txn.organizationid AS "CreditOrganizationId"
    		,(
    			select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid)
    			) AS "LedgerId"
    		,(select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid)) AS "SubLedgerId"
    	from bil_txn_billingtransactionitems itm
    		,bil_txn_billingtransaction txn
    	where txn.billingtransactionid = itm.billingtransactionid
    		and (txn.createdon)::date = p_transactiondate --changed: sud-10aug'20--Corrected to TransactionCreatedOn from ItemCreatedOn
    		AND itm.BillingTransactionId IS NOT NULL
    		AND txn.PaymentMode = 'credit'
    		and coalesce(itm.iscreditbillsync, 0) = 0; -- include only not-synced data for creditbill case--
END;
$$ LANGUAGE plpgsql;