CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptreturnvattransactions(
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
     exec sp_acc_post_inv_getgoodreceiptreturnvattransactions '2023-06-22',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                initial draft of sp to get inventory good receipt return (vat) transactions.
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
    	,0 AS "DrCr"
    	,'INV_PurchaseReturn' AS "BaseTransactionType"
    	,returntovendorid AS "TransactionRefNo"
    from (
    	select 
    		returntovendorid as referenceid
    		,'INV_GoodReceiptReturn_VAT' AS "TransactionType"
    		,(grreturn.vattotal) AS "TotalAmount"
    		,cast(grreturn.createdon as date) AS "TransactionDate"
    		,'CRN: ' || (grreturn.creditnoteid)::varchar ||' for-' || (cast(grreturn.createdon as date))::varchar AS "Description"
    		,(select ledgerid from acc_ledger where name='LCL_DUTIES_AND_TAXES_VAT') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,grreturn.returntovendorid
    	from inv_txn_returntovendor grreturn
    		where (grreturn.returndate)::date = p_transactiondate
    	and coalesce(grreturn.istransferredtoacc,0) = 0 
    	and grreturn.vattotal > 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.returntovendorid;
END;
$$ LANGUAGE plpgsql;