CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getconsumabledispatchmainstoretransaction(
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
     exec sp_acc_post_phrm_getconsumabledispatchmainstoretransaction '2023-06-27',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/27th june 23                 initial draft of sp to get pharmacy consumable dispatch (main store) transactions.
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
    	,'PHRM_ConsumableDispatch' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		stocktransactionid as referenceid
    		,'PHRM_ConsumableDispatch_MainStore' AS "TransactionType"
    		,(stocktxn.costprice * stocktxn.outqty) AS "TotalAmount"
    		,cast(stocktxn.transactiondate as date) AS "TransactionDate"
    		,'WARD SUPPLY FOR (' || (cast(stocktxn.transactiondate as date))::varchar ||')' AS "Description"
    		,(select ledgerid from acc_ledger where name='IOS_WARD_/_DEPARTMENT_SUPPLY') AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from phrm_txn_stocktransaction stocktxn
    	where (stocktxn.transactiondate)::date = p_transactiondate
    	and coalesce(stocktxn.istransferedtoacc,0) = 0 
    	and stocktxn.transactiontype='dispensary-dispatched-item'
    	and stocktxn.outqty > 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;