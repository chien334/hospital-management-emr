CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getinternalcreditorganizationsales(
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
     exec sp_acc_post_phrm_getinternalcreditorganizationsales '2023-06-19',1
    
     change history
    sn.                auther/timestamp                   description
    1.                 devn/19th june 23                initial draft of sp to get pharmacy opd credit sales internal(medicare) detail.
    */
    
    RETURN QUERY SELECT 
    	'PHRM_Credit_Sale' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
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
    		invoiceid as "referenceid"
    		,invoice.creditamount AS "TotalAmount"
    		,cast(invoice.createon as date) AS "TransactionDate"
    		,'STAFF MEDICARE -' || (cast(invoice.createon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,invoice.organizationid
    	from phrm_txn_invoice invoice
    	join ins_medicaremember patient on invoice.patientid = patient.patientid
    	join acc_ledger_mapping map on map.referenceid = patient.medicarememberid
    	join bil_mst_credit_organization org on invoice.organizationid = org.organizationid
    	where (invoice.createon)::date = p_transactiondate 
    	and invoice.paymentmode = 'credit'
    	and map.ledgertype = 'MedicareMember'
    	and org.creditorganizationcode='MEDICARE'
    	and coalesce(invoice.istransferredtoacc, 0) = 0
    	) innertable
    group by 
    	innertable.organizationid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;