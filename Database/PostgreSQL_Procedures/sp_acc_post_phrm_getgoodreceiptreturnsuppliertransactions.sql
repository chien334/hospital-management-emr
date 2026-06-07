CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getgoodreceiptreturnsuppliertransactions(
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
     exec sp_acc_post_phrm_getgoodreceiptreturnsuppliertransactions '2023-06-21',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/21th june 23                initial draft of sp to get pharmacy good receipt return (supplier) transactions.
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
    	,1 AS "DrCr"
    	,'PHRM_PurchaseReturn' AS "BaseTransactionType"
    	,returntosupplierid AS "TransactionRefNo"
    from (
    	select 
    		returntosupplierid as referenceid
    		,'PHRM_GoodReceiptReturn_Supplier' AS "TransactionType"
    		,(grreturn.totalamount) AS "TotalAmount"
    		,cast(grreturn.createdon as date) AS "TransactionDate"
    		,'CRN: ' || (grreturn.creditnoteprintid)::varchar || ' (' || (cast(grreturn.createdon as date))::varchar ||')' || ' Ref. GRN: ' || (grreturn.goodreceiptid)::varchar || '/' || supplier.suppliername  AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,grreturn.returntosupplierid
    	from phrm_returntosupplier grreturn
    	join acc_ledger_mapping map on grreturn.supplierid = map.referenceid
    	join phrm_mst_supplier supplier on grreturn.supplierid = supplier.supplierid
    		where (grreturn.returndate)::date = p_transactiondate
    	and coalesce(grreturn.istransferredtoacc,0) = 0 
    	and map.ledgertype='pharmacysupplier'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.returntosupplierid;
END;
$$ LANGUAGE plpgsql;