CREATE OR REPLACE FUNCTION sp_acc_post_bil_getdiscounts(
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
     exec sp_acc_post_bil_getdiscounts '2023-07-03',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/12th june 23                initial draft of sp to get discount detail.
    2.                 devn/29th aug 23                 string_agg() function unable to hold large set of data.. 
    							                        so added convert(text) to fix it.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(discountamount) AS "TotalAmount"
    	,string_agg((referenceid)::varchar, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,1 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billingtransactionitemid as "referenceid"
    		,'BIL_Discount' AS "TransactionType"
    		,itm.discountamount as discountamount
    		,cast(case when itm.billingtype = 'inpatient' then (txn.createdon)::date 
    			else (itm.createdon)::date end as date) AS "TransactionDate"
    		,'Free and concession given for ' || (cast(case when itm.billingtype = 'inpatient' then (txn.createdon)::date 
    			 else (itm.createdon)::date end as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from bil_txn_billingtransactionitems itm
    		 join bil_txn_billingtransaction txn on itm.billingtransactionid = txn.billingtransactionid
    	where 
    	p_transactiondate =
    	case when itm.billingtype = 'inpatient' then (txn.createdon)::date 
    	 else (itm.createdon)::date end
    	and itm.billingtransactionid is not null 
    	and (coalesce(itm.iscashbillsync, 0) = 0 or coalesce(itm.iscreditbillsync,0) = 0 )
    	and itm.discountamount > 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;