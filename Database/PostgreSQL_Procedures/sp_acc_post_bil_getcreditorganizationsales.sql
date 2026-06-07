CREATE OR REPLACE FUNCTION sp_acc_post_bil_getcreditorganizationsales(
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
     exec sp_acc_post_bil_getcreditorganizationsales '2023-10-08',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get billing credit sales detail.
    */
    
    RETURN QUERY SELECT 
    	'BIL_Credit_Sale' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg((referenceid)::varchar, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billingtransactionitemid as "referenceid"
    		,case when itm.copaymentcreditamount > 0 then itm.copaymentcreditamount
    			else itm.totalamount end AS "TotalAmount"
    		,cast(txn.createdon as date) AS "TransactionDate"
    		,'Credit sale ON - '||(cast(txn.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,txn.organizationid
    	from bil_txn_billingtransactionitems itm
    	join bil_txn_billingtransaction txn on itm.billingtransactionid = txn.billingtransactionid
    	join acc_ledger_mapping map on map.referenceid = txn.organizationid
    	join bil_cfg_fiscalyears fy  on txn.fiscalyearid = fy.fiscalyearid  
    	join pat_patient patient on txn.patientid = patient.patientid
    	join bil_mst_credit_organization org on txn.organizationid = org.organizationid
    	where (txn.createdon)::date = p_transactiondate
    	and itm.billingtransactionid is not null 
    	and txn.paymentmode = 'credit'
    	and map.ledgertype = 'creditorganization'
    	and org.creditorganizationcode <> 'MEDICARE'
    	and coalesce(itm.iscreditbillsync, 0) = 0
    	) innertable
    group by 
    	innertable.organizationid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;