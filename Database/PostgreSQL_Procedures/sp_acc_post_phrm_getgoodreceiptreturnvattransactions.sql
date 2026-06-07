CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getgoodreceiptreturnvattransactions(
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
     exec sp_acc_post_phrm_getgoodreceiptreturnvattransactions '2023-06-21',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/21th june 23                initial draft of sp to get pharmacy good receipt return (vat) transactions.
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
    	,'PHRM_PurchaseReturn' AS "BaseTransactionType"
    	,returntosupplierid AS "TransactionRefNo"
    from (
    	select 
    		returntosupplierid as referenceid
    		,'PHRM_GoodReceiptReturn_VAT' AS "TransactionType"
    		,(grreturn.vatamount) AS "TotalAmount"
    		,cast(grreturn.createdon as date) AS "TransactionDate"
    		,'CRN: ' || (grreturn.creditnoteprintid)::varchar ||' for-' || (cast(grreturn.createdon as date))::varchar AS "Description"
    		,(select ledgerid from acc_ledger where name='ACA_VAT_13%_PAYABLE') AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,grreturn.returntosupplierid
    	from phrm_returntosupplier grreturn
    		where (grreturn.returndate)::date = p_transactiondate
    	and coalesce(grreturn.istransferredtoacc,0) = 0 
    	and grreturn.vatamount > 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.returntosupplierid;
END;
$$ LANGUAGE plpgsql;