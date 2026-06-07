CREATE OR REPLACE FUNCTION sp_acc_post_bil_getinternalcreditorganizationsales(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "TransactionType" TIMESTAMP,
    "LedgerId" INT,
    "SubLedgerId" INT,
    "TotalAmount" DECIMAL,
    "ReferenceIdCSV" INT,
    "TransactionDate" TIMESTAMP,
    "Description" TIMESTAMP,
    "DisplaySequence" VARCHAR,
    "DrCr" VARCHAR,
    "BaseTransactionType" TIMESTAMP,
    "TransactionRefNo" TIMESTAMP
) AS $$
BEGIN
    /*
     exec sp_acc_post_bil_getinternalcreditorganizationsales '2023-06-26',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get billing credit sales internal(medicare) detail.
    */
    
    RETURN QUERY SELECT 
    	'BIL_Credit_Sale' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billingtransactionitemid as "referenceid"
    		,case when itm.iscopayment = 1 and itm.copaymentcreditamount > 0 then itm.copaymentcreditamount
    			else itm.totalamount end AS "TotalAmount"
    		,cast(itm.createdon as date) AS "TransactionDate"
    		,'STAFF MEDICARE -' || (cast(itm.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,txn.organizationid
    		,txn.billingtransactionid
    	from bil_txn_billingtransactionitems itm
    	join bil_txn_billingtransaction txn on itm.billingtransactionid = txn.billingtransactionid
    	join ins_medicaremember patient on txn.patientid = patient.patientid
    	join acc_ledger_mapping map on map.referenceid = patient.medicarememberid
    	join bil_mst_credit_organization org on txn.organizationid = org.organizationid
    	where txn.billingtransactionid = itm.billingtransactionid and (itm.createdon)::date = p_transactiondate
    	and itm.billingtransactionid is not null 
    	and txn.paymentmode = 'credit'
    	and map.ledgertype = 'MedicareMember'
    	and org.creditorganizationcode='MEDICARE'
    	and coalesce(itm.iscreditbillsync, 0) = 0
    	) innertable
    group by 
    	innertable.organizationid
    	,billingtransactionid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;