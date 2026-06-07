CREATE OR REPLACE FUNCTION sp_acc_post_inv_getconsumptionsubstoretransaction(
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
     exec sp_acc_post_inv_getconsumptionsubstoretransaction '2023-10-04',3
     change history
    sn.                auther/timestamp                   description
    1.                 devn/26th june 23                 initial draft of sp to get inventory consumption (sub store/subcategory for charak) transactions.
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
    	,1 AS "DrCr"
    	,'INV_Consumption' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		stocktransactionid as referenceid
    		,'INV_Consumption_SubStore' AS "TransactionType"
    		,(stocktxn.costprice * stocktxn.outqty) AS "TotalAmount"
    		,cast(stocktxn.transactiondate as date) AS "TransactionDate"
    		, 'Inventory Consumption For (' || (cast(stocktxn.transactiondate as date))::varchar ||')' AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    	from inv_txn_stocktransaction stocktxn
    	join inv_mst_item item on stocktxn.itemid = item.itemid
    	join inv_mst_itemsubcategory category on item.subcategoryid = category.subcategoryid
    	join acc_ledger_mapping map on category.subcategoryid = map.referenceid
    	where (stocktxn.transactiondate)::date = p_transactiondate
    	and coalesce(stocktxn.istransferredtoacc,0) = 0 
    	and map.ledgertype='inventorysubcategory'
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