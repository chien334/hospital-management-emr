CREATE OR REPLACE FUNCTION sp_acc_post_bil_getcreditorganizationsalesreturn(
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
     exec sp_acc_post_bil_getcreditorganizationsalesreturn '2023-10-10',3
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get billing credit sales return detail.
    2.                 devn/12th oct 23                 get billreturninvoice amount for co-payment scenerio.
    */
    
    RETURN QUERY SELECT 
    	'BIL_Credit_SaleReturn' AS "TransactionType"
    	,coalesce(innertable.ledgerid,0) AS "LedgerId"
    	,coalesce(innertable.subledgerid,0) AS "SubLedgerId"
    	,innertable.subtotal AS "TotalAmount"
    	,innertable.referenceid AS "ReferenceIdCSV"
    	,innertable.transactiondate AS "TransactionDate"
    	,innertable.description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		string_agg((billreturnitemid)::varchar, ',') as "referenceid"
    		,case when txn.returncreditamount > 0 then txn.returncreditamount else txn.totalamount end as "subtotal"
    		,cast(txn.createdon as date) AS "TransactionDate"
    		,'Credit sale return ON - '||(cast(txn.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,txn.organizationid
    		from 
    		bil_txn_invoicereturn txn 
    		join bil_txn_invoicereturnitems items on txn.billreturnid = items.billreturnid 
    	join acc_ledger_mapping map on map.referenceid = txn.organizationid
    	join bil_cfg_fiscalyears fy  on txn.fiscalyearid = fy.fiscalyearid  
    	join pat_patient patient on txn.patientid = patient.patientid
    	join bil_mst_credit_organization org on txn.organizationid = org.organizationid
    	where (txn.createdon)::date = p_transactiondate
    	and txn.billingtransactionid is not null 
    	and txn.paymentmode = 'credit'
    	and map.ledgertype = 'creditorganization'
    	and org.creditorganizationcode <> 'MEDICARE'
    	and coalesce(items.iscreditbillsynctoacc, 0) = 0
    	group by txn.billreturnid,txn.createdon,ledgerid,subledgerid,txn.organizationid,returncreditamount,totalamount
    	) innertable;
END;
$$ LANGUAGE plpgsql;