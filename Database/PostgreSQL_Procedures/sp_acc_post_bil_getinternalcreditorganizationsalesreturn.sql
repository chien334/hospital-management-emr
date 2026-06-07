CREATE OR REPLACE FUNCTION sp_acc_post_bil_getinternalcreditorganizationsalesreturn(
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
     exec sp_acc_post_bil_getinternalcreditorganizationsalesreturn '2023-06-14',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/13th june 23                initial draft of sp to get billing credit sales return internal(medicare) detail.
    */
    
    RETURN QUERY SELECT 
    	'BIL_Credit_SaleReturn' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(subtotal) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'BIL_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		billingtransactionitemid as "referenceid"
    		,returncreditamount as "subtotal"
    		,cast(itm.createdon as date) AS "TransactionDate"
    		,'STAFF MEDICARE -' || (cast(itm.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,btxn.organizationid
    		,txn.billingtransactionid
    		from bil_txn_invoicereturnitems itm
    		join bil_txn_invoicereturn txn on itm.billreturnid = txn.billreturnid
    		join bil_txn_billingtransaction btxn on itm.billingtransactionid = btxn.billingtransactionid
    	join bil_cfg_fiscalyears fy  on txn.fiscalyearid = fy.fiscalyearid  
    	join ins_medicaremember patient on txn.patientid = patient.patientid
    	join acc_ledger_mapping map on map.referenceid = patient.medicarememberid
    	join bil_mst_credit_organization org on btxn.organizationid = org.organizationid
    	where txn.billingtransactionid = itm.billingtransactionid 
    	and (itm.createdon)::date = p_transactiondate
    	and itm.billingtransactionid is not null 
    	and txn.paymentmode = 'credit'
    	and map.ledgertype = 'MedicareMember'
    	and org.creditorganizationcode = 'MEDICARE'
    	and coalesce(itm.iscreditbillsynctoacc, 0) = 0
    	) innertable
    group by 
    	innertable.organizationid
    	,billingtransactionid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;