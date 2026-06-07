CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getgoodreceiptsuppliertransactions(
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
     exec sp_acc_post_phrm_getgoodreceiptsuppliertransactions '2023-06-20',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/21th june 23                initial draft of sp to get pharmacy  good receipt transactions.
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
    	,'PHRM_Purchase' AS "BaseTransactionType"
    	,goodreceiptid AS "TransactionRefNo"
    from (
    	select 
    		goodreceiptid as referenceid
    		,'PHRM_GoodReceipt_Supplier' AS "TransactionType"
    		,(gr.totalamount) AS "TotalAmount"
    		,cast(gr.createdon as date) AS "TransactionDate"
    		,'PO:' || (coalesce(gr.purchaseorderid,0))::varchar || '('|| (cast(gr.supplierbilldate as date))::varchar||')'||' / GRN: ' || (gr.goodreceiptprintid)::varchar || '(' || (cast(gr.createdon as date))::varchar ||') /' || supplier.suppliername || '/' || upper(gr.transactiontype) ||' Purchase.'  AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,gr.goodreceiptid
    	from phrm_goodsreceipt gr
    	join acc_ledger_mapping map on gr.supplierid = map.referenceid
    	join phrm_mst_supplier supplier on gr.supplierid = supplier.supplierid
    		where (gr.createdon)::date = p_transactiondate
    	and coalesce(gr.istransferredtoacc,0) = 0 
    	and map.ledgertype='pharmacysupplier'
    	and gr.iscancel = 0
    	--and gr.transactiontype='credit'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.goodreceiptid;
END;
$$ LANGUAGE plpgsql;