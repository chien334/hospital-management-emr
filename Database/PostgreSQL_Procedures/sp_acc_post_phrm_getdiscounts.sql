CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getdiscounts(
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
     exec sp_acc_post_phrm_getdiscounts '2023-06-18',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/18th june 23                initial draft of sp to get pharmacy sale discount detail.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(discountamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoiceid as "referenceid"
    		,'PHRM_Discount' AS "TransactionType"
    		,invoice.discountamount as discountamount
    		,(invoice.createon)::date  AS "TransactionDate"
    		,'Free and concession given for ' || (cast(invoice.createon as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from phrm_txn_invoice invoice
    	where (invoice.createon)::date = p_transactiondate
    	and (coalesce(invoice.istransferredtoacc, 0) = 0)
    	and invoice.discountamount > 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;