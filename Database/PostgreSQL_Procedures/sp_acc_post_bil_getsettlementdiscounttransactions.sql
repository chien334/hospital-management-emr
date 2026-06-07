CREATE OR REPLACE FUNCTION sp_acc_post_bil_getsettlementdiscounttransactions(
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
     exec sp_acc_post_bil_getsettlementdiscounttransactions '2023-06-16',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/15th june 23                initial draft of sp to get billing settlement discount transactions.
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
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		settlementid as referenceid
    		,'BIL_Settlement_Discount' AS "TransactionType"
    		,settlement.discountamount AS "TotalAmount"
    		,cast(settlement.settlementdate as date) AS "TransactionDate"
    		,'Free and Concession given during settlement on ' || (cast(settlement.createdon as date))::varchar AS "Description"
    		,(
    			select ledgerid
    			from acc_ledger
    			where name = 'EIE_ADMINISTRATION_EXPENSES_TRADE_DISCOUNT'
    			) AS "LedgerId"
    		,0 AS "SubLedgerId"
    	from bil_txn_settlements settlement
    		where (settlement.settlementdate)::date = p_transactiondate
    	and coalesce(settlement.issynctoacc,0) = 0 
    	and settlement.discountamount > 0
    	and settlement.modulename='Billing'
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;