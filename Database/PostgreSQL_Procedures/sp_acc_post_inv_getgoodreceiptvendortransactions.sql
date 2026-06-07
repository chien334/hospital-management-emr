CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptvendortransactions(
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
     exec sp_acc_post_inv_getgoodreceiptvendortransactions '2023-06-22',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                 initial draft of sp to get inventory good receipt (vendor detail) transactions.
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
    	,'INV_Purchase' AS "BaseTransactionType"
    	,goodsreceiptid AS "TransactionRefNo"
    from (
    	select 
    		goodsreceiptid as referenceid
    		,'INV_GoodReceipt_Vendor' AS "TransactionType"
    		,(gr.totalamount) AS "TotalAmount"
    		,cast(gr.createdon as date) AS "TransactionDate"
    		,'PO:' || (coalesce(gr.purchaseorderid,0))::varchar || '('|| (cast(gr.vendorbilldate as date))::varchar||')'||' / GRN: ' || (gr.goodsreceiptno)::varchar || '(' || (cast(gr.createdon as date))::varchar ||') /' || vendor.vendorname || '/' || upper(gr.paymentmode) ||' Purchase.' AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,gr.goodsreceiptid
    	from inv_txn_goodsreceipt gr
    	join acc_ledger_mapping map on gr.vendorid = map.referenceid
    	join inv_mst_vendor vendor on gr.vendorid = vendor.vendorid
    		where (gr.createdon)::date = p_transactiondate
    	and coalesce(gr.istransferredtoacc,0) = 0 
    	and map.ledgertype='inventoryvendor'
    	and gr.iscancel != 1
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.goodsreceiptid;
END;
$$ LANGUAGE plpgsql;