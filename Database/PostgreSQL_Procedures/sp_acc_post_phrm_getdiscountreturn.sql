CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getdiscountreturn(
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
     exec sp_acc_post_phrm_getdiscountreturn '2023-06-19',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/19th june 23                initial draft of sp to get pharmacy discount return detail.
    */
    
    RETURN QUERY SELECT 
    	'PHRM_Discount_Return' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(returndiscountamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoicereturnid as referenceid
    		,discountamount as returndiscountamount
    		,cast(retinvoice.createdon as date) AS "TransactionDate"
    		,'Free and concession return for ' || (cast(retinvoice.createdon as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    		from phrm_txn_invoicereturn retinvoice
    	where (retinvoice.createdon)::date = p_transactiondate
    	and coalesce(retinvoice.istransferredtoacc, 0) = 0 
    	and retinvoice.discountamount > 0
    	) innertable
    group by 
    	ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;