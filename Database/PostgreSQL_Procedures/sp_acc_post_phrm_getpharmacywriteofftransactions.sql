CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getpharmacywriteofftransactions(
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
     exec sp_acc_post_phrm_getpharmacywriteofftransactions '2023-06-27',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/27th june 23                initial draft of sp to get pharmacy writeoff transactions.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(case when drcr = 0 then (select ledgerid from acc_ledger where name='IOS_WARD_/_DEPARTMENT_SUPPLY')
    		else (select ledgerid from acc_ledger where name='EHC_CONSUMABLE_:_PHARMACY') end ,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,drcr AS "DrCr"
    	,'PHRM_WriteOff' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		writeoffid as referenceid
    		,'PHRM_WriteOffItems' AS "TransactionType"
    		,(wr.totalamount) AS "TotalAmount"
    		,cast(wr.createdon as date) AS "TransactionDate"
    		,'PHARMACY WRITE-OFF ITEMS FOR :' || '(' || (cast(wr.createdon as date))::varchar ||')'  AS "Description"
    		,0 AS "LedgerId"
    		,0 AS "SubLedgerId"
    		,(debitcredit.value)::boolean AS "DrCr"
    	from phrm_writeoff wr
    	cross join (
    		select value
    		from string_split('0,1', ',')
    	) as debitcredit
    		where (wr.createdon)::date = p_transactiondate
    	and coalesce(wr.istransferredtoacc,0) = 0 
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype
    	,innertable.drcr
    	order by innertable.drcr desc;
END;
$$ LANGUAGE plpgsql;