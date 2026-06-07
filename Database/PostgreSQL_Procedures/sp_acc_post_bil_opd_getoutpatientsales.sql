CREATE OR REPLACE FUNCTION sp_acc_post_bil_opd_getoutpatientsales(
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
     exec sp_acc_post_bil_opd_getoutpatientsales '2023-08-18',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/12th june 23                initial draft of sp to get opd billing sales.
    2.                 devn/4th sept 23                 remove outpatient/inpatient segregation.
    */
    
    RETURN QUERY SELECT 
    	transactiontype
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(subtotal) AS "TotalAmount"
    	,string_agg((referenceid)::varchar, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billingtransactionitemid as "referenceid"
    		,'BIL_OPD_Sales' AS "TransactionType"
    		,itm.subtotal as "subtotal"
    		,cast(txn.createdon as date) AS "TransactionDate"
    		,'Service Sale Collection on ' ||  || (cast(txn.createdon as date))::varchar AS "Description"
    		,(
    			select fn_acc_getincomeledgerid(servicedepartmentid, serviceitemid, p_hospitalid,'outpatient')
    			) AS "LedgerId"
    		,(
    			select "fn_acc_getincomesubledgerid"(servicedepartmentid, serviceitemid, p_hospitalid,'outpatient')
    			) AS "SubLedgerId"
    	from bil_txn_billingtransactionitems itm
    		inner join bil_txn_billingtransaction txn on txn.billingtransactionid = itm.billingtransactionid
    	where (txn.createdon)::date = p_transactiondate
    	and itm.billingtransactionid is not null 
    	--and txn.paymentmode = 'cash' 
    	--and itm.billingtype = 'outpatient' 
    	and coalesce(itm.iscashbillsync, 0) = 0
    	) innertable
    group by innertable.ledgerid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;