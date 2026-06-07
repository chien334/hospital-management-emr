CREATE OR REPLACE FUNCTION sp_acc_post_inv_getconsumabledispatchcentralstoretransaction(
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
     exec sp_acc_post_inv_getconsumabledispatchcentralstoretransaction '2023-06-26',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/26th june 23                 initial draft of sp to get inventory consumable dispatch (centralstore) transactions.
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
    	,'INV_ConsumableDispatch' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		stocktransactionid as referenceid
    		,'INV_ConsumableDispatch_CentralStore' AS "TransactionType"
    		,(stocktxn.costprice * stocktxn.outqty) AS "TotalAmount"
    		,cast(stocktxn.transactiondate as date) AS "TransactionDate"
    		, 'STORE ALLOCATION FOR (' || (cast(stocktxn.transactiondate as date))::varchar ||')' AS "Description"
    		,(select ledgerid from acc_ledger where name='ACA_INVENTORY_INVENTORY-HOSPITAL') AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from inv_txn_stocktransaction stocktxn
    	join inv_mst_item item on stocktxn.itemid = item.itemid
    	where (stocktxn.transactiondate)::date = p_transactiondate
    	and coalesce(stocktxn.istransferredtoacc,0) = 0 
    	and stocktxn.transactiontype='dispatched-item-from'
    	and coalesce(item.isfixedassets,0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;