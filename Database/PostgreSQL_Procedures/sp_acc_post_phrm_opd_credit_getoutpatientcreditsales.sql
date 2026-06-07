CREATE OR REPLACE FUNCTION sp_acc_post_phrm_opd_credit_getoutpatientcreditsales(
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
     exec sp_acc_post_phrm_opd_credit_getoutpatientcreditsales '2023-06-18',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/18th june 23                initial draft of sp to get opd (credit) pharmacy sales.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce((select subledgerid from acc_mst_subledger where ledgerid = innertable.ledgerid and subledgername = 'CREDIT'),0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,'OP SALE Invoice Ref. No.(' || string_agg('PH-'|| (innertable.invoiceprintid)::varchar,',') || ') for ' || (cast(innertable.transactiondate as date))::varchar AS "Description"
    
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoiceid as "referenceid"
    		,'PHRM_OPD_CREDIT_Sales' AS "TransactionType"
    		,invoice.subtotal AS "TotalAmount"
    		,cast(invoice.createon as date) AS "TransactionDate"
    		,null AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'IOS_PHARMACY_SALES_-_OPD'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,invoice.invoiceprintid
    	from phrm_txn_invoice invoice
    	where 
    	(invoice.createon)::date = p_transactiondate
    	and invoice.paymentmode = 'credit' 
    	and invoice.visittype = 'outpatient' 
    	and coalesce(invoice.istransferredtoacc, 0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;