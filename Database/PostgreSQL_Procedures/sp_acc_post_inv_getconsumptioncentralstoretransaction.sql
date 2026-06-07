CREATE OR REPLACE FUNCTION sp_acc_post_inv_getconsumptioncentralstoretransaction(
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
     exec sp_acc_post_inv_getconsumptioncentralstoretransaction '2023-10-04',3
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/15th oct 23                 initial draft of sp to get inventory consumption transactions for central store.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg((referenceid)::varchar, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'INV_Consumption' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		stocktransactionid as referenceid
    		,'INV_Consumption_CentralStore' AS "TransactionType"
    		,(stocktxn.costprice * stocktxn.outqty) AS "TotalAmount"
    		,cast(stocktxn.transactiondate as date) AS "TransactionDate"
    		, 'Inventory Consumption For (' || (cast(stocktxn.transactiondate as date))::varchar ||')' AS "Description"
    		,(select ledgerid from acc_ledger where name='ACA_MERCHANDISE_INVENTORYMERCHANDISE_INVENTORY') AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from inv_txn_stocktransaction stocktxn
    	join inv_mst_item item on stocktxn.itemid = item.itemid
    	where (stocktxn.transactiondate)::date = p_transactiondate
    	and coalesce(stocktxn.istransferredtoacc,0) = 0 
    	and stocktxn.transactiontype='consumption-items'
    	and item.itemtype='Consumables'
    	and coalesce(item.isfixedassets,0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;