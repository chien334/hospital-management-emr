CREATE OR REPLACE FUNCTION sp_acc_post_inv_getgoodreceiptreturnvendortransactions(
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
     exec sp_acc_post_inv_getgoodreceiptreturnvendortransactions '2023-06-22',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/22th june 23                 initial draft of sp to get inventory good receipt return (vendor) transactions.
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
    	,'INV_PurchaseReturn' AS "BaseTransactionType"
    	,returntovendorid AS "TransactionRefNo"
    from (
    	select 
    		returntovendorid as referenceid
    		,'INV_GoodReceiptReturn_Vendor' AS "TransactionType"
    		,(grreturn.totalamount) AS "TotalAmount"
    		,cast(grreturn.createdon as date) AS "TransactionDate"
    		,'CRN: ' || (grreturn.creditnoteid)::varchar || ' (' || (cast(grreturn.createdon as date))::varchar ||')' ||'/' || vendor.vendorname  AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,grreturn.returntovendorid
    	from inv_txn_returntovendor grreturn
    	join acc_ledger_mapping map on grreturn.vendorid = map.referenceid
    	join inv_mst_vendor vendor on grreturn.vendorid = vendor.vendorid
    		where (grreturn.returndate)::date = p_transactiondate
    	and coalesce(grreturn.istransferredtoacc,0) = 0 
    	and map.ledgertype='inventoryvendor'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.returntovendorid;
END;
$$ LANGUAGE plpgsql;