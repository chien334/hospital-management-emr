CREATE OR REPLACE FUNCTION sp_acc_post_phrm_opd_credit_getoutpatientcreditsalereturn(
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
     exec sp_acc_post_phrm_opd_credit_getoutpatientcreditsalereturn '2023-06-19',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/19th june 23                initial draft of sp to get opd (credit) pharmacy sales return.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce((select subledgerid from acc_mst_subledger where ledgerid = innertable.ledgerid and subledgername = 'CREDIT'),0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoicereturnid as referenceid
    		,'PHRM_OPD_CREDIT_Sales_Return' AS "TransactionType"
    		,retinvoice.subtotal AS "TotalAmount"
    		,cast(retinvoice.createdon as date) AS "TransactionDate"
    		,'OP SALE Return Cedit Note Ref. No.(CR-PH-' || (retinvoice.creditnoteid)::varchar  || ') for ' || (cast(retinvoice.createdon as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'IOS_PHARMACY_SALES_-_OPD'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from phrm_txn_invoicereturn retinvoice
    	where 
    	(retinvoice.createdon)::date = p_transactiondate
    	and retinvoice.paymentmode = 'credit' 
    	and retinvoice.visittype = 'outpatient' 
    	and coalesce(retinvoice.istransferredtoacc, 0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;