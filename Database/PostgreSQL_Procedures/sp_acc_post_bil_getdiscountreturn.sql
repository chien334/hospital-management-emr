CREATE OR REPLACE FUNCTION sp_acc_post_bil_getdiscountreturn(
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
     exec sp_acc_post_bil_getdiscountreturn '2023-06-14',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/14th june 23                initial draft of sp to get billing discount return detail
    */
    
    RETURN QUERY SELECT 
    	'BIL_Discount_Return' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(returndiscountamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billreturnitemid as referenceid
    		,retdiscountamount as returndiscountamount
    		,cast(itm.createdon as date) AS "TransactionDate"
    		,'Free and concession return for ' || (cast(itm.createdon as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    		from bil_txn_invoicereturnitems itm
    		join bil_txn_invoicereturn txn on itm.billreturnid = txn.billreturnid
    	where (itm.createdon)::date = p_transactiondate
    	and itm.billingtransactionid is not null 
    	and (coalesce(itm.iscreditbillsynctoacc, 0) = 0 or coalesce(itm.iscreditbillsynctoacc,0) = 0)
    	and itm.retdiscountamount > 0
    	) innertable
    group by 
    	ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;