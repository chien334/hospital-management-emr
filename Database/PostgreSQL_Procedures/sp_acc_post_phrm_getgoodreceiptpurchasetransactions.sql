CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getgoodreceiptpurchasetransactions(
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
     exec sp_acc_post_phrm_getgoodreceiptpurchasetransactions '2023-06-20',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/21th june 23                initial draft of sp to get pharmacy good receipt (purchase) transactions.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce((select  subledgerid from acc_mst_subledger where ledgerid = innertable.ledgerid and isdefault = 1 limit 1),0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'PHRM_Purchase' AS "BaseTransactionType"
    	,goodreceiptid AS "TransactionRefNo"
    from (
    	select 
    		goodreceiptid as referenceid
    		,'PHRM_GoodReceipt_Purchase' AS "TransactionType"
    		,(gr.totalamount - gr.vatamount) AS "TotalAmount"
    		,cast(gr.createdon as date) AS "TransactionDate"
    		,'Pharmacy GRN: ' || (gr.goodreceiptprintid)::varchar ||' for-' || (cast(gr.createdon as date))::varchar || '/' || upper(gr.transactiontype) ||' Purchase.'  AS "Description"
    		,(select ledgerid from acc_ledger where name='EDE_COST_OF_GOODS_SOLD_COGS') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,gr.goodreceiptid
    	from phrm_goodsreceipt gr
    		where (gr.createdon)::date = p_transactiondate
    	and coalesce(gr.istransferredtoacc,0) = 0 
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