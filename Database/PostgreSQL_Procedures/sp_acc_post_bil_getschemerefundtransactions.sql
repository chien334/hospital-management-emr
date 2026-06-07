CREATE OR REPLACE FUNCTION sp_acc_post_bil_getschemerefundtransactions(
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
     exec sp_acc_post_bil_getschemerefundtransactions '2023-06-16',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/16th june 23                initial draft of sp to get scheme refund transactions.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
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
    		txn.schemerefundid as referenceid
    		,'Scheme_Refund' AS "TransactionType"
    		,txn.refundamount AS "TotalAmount"
    		,cast(txn.createdon as date) AS "TransactionDate"
    		,'Scheme Refund To: ' || patient.shortname || ', On: ' || (cast(txn.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,txn.schemeid
    		,txn.patientid
    	from bil_txn_schemerefund txn
    	join pat_patient patient on txn.patientid = patient.patientid
    	join 
    	(select scheme.schemeid,coalesce(scheme.defaultcreditorganizationid,1) as defaultcreditorganizationid from bil_cfg_scheme scheme) as scheme
    	on txn.schemeid = scheme.schemeid
    	join bil_mst_credit_organization org on scheme.defaultcreditorganizationid = org.organizationid
    	join acc_ledger_mapping map on org.organizationid = map.referenceid
    
    		where (txn.createdon)::date = p_transactiondate
    	and coalesce(txn.istransferredtoacc,0) = 0 
    	and map.ledgertype = 'creditorganization'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,innertable.schemeid
    	,innertable.patientid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;