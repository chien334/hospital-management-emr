CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptvattransactions(
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
     exec sp_acc_post_inv_getgoodreceiptvattransactions '2023-06-22',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                initial draft of sp to get inventory good receipt (vat) transactions.
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
    	,'INV_Purchase' AS "BaseTransactionType"
    	,goodsreceiptid AS "TransactionRefNo"
    from (
    	select 
    		goodsreceiptid as referenceid
    		,'INV_GoodReceipt_VAT' AS "TransactionType"
    		,(gr.vattotal) AS "TotalAmount"
    		,cast(gr.createdon as date) AS "TransactionDate"
    		,'Inventory GRN: ' || (gr.goodsreceiptno)::varchar ||' for-' || (cast(gr.createdon as date))::varchar || '/' || upper(gr.paymentmode) ||' Purchase.' AS "Description"
    		,(select ledgerid from acc_ledger where name='LCL_DUTIES_AND_TAXES_VAT') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,gr.goodsreceiptid
    	from inv_txn_goodsreceipt gr
    		where (gr.createdon)::date = p_transactiondate
    	and coalesce(gr.istransferredtoacc,0) = 0 
    	and gr.vattotal > 0
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