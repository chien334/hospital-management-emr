CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getsettlementtransactions(
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
     exec sp_acc_post_phrm_getsettlementtransactions '2023-06-20',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/20th june 23                initial draft of sp to get pharmacy settlement transactions.
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
    	,0 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		settlementid as referenceid
    		,'PHRM_Settlement' AS "TransactionType"
    		,settlement.collectionfromreceivable AS "TotalAmount"
    		,cast(settlement.settlementdate as date) AS "TransactionDate"
    		,'PHRM-Credit Invoices Settled On ' || (cast(settlement.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    	from bil_txn_settlements settlement
    	join acc_ledger_mapping map on settlement.organizationid = map.referenceid
    		where (settlement.settlementdate)::date = p_transactiondate
    	and coalesce(settlement.issynctoacc,0) = 0 
    	and map.ledgertype = 'creditorganization'
    	and settlement.modulename='Dispensary'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;