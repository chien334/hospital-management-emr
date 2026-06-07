CREATE OR REPLACE FUNCTION sp_acc_post_phrm_getcreditorganizationsales(
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
     exec sp_acc_post_phrm_getcreditorganizationsales '2023-06-18',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/18th june 23                initial draft of sp to get pharmacy outpatient credit sales detail(credit organization).
    */
    
    RETURN QUERY SELECT 
    	'PHRM_OPD_Credit_Sale' AS "TransactionType"
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
    		invoiceid as referenceid
    		,invoice.totalamount AS "TotalAmount"
    		,cast(invoice.createon as date) AS "TransactionDate"
    		,(patient.patientcode)::varchar || '-' || patient.shortname || '-CLAIMCODE-'|| (coalesce(invoice.claimcode,''))::varchar || '-' || fy.fiscalyearformatted||'-PH'||(invoice.invoiceid)::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,invoice.organizationid
    		,invoice.invoiceid
    	from phrm_txn_invoice invoice
    	join acc_ledger_mapping map on map.referenceid = invoice.organizationid
    	join bil_cfg_fiscalyears fy  on invoice.fiscalyearid = fy.fiscalyearid  
    	join pat_patient patient on invoice.patientid = patient.patientid
    	join bil_mst_credit_organization org on invoice.organizationid = org.organizationid
    	where (invoice.createon)::date = p_transactiondate
    	and invoice.paymentmode = 'credit'
    	and map.ledgertype = 'creditorganization'
    	and org.creditorganizationcode <> 'MEDICARE'
    	and coalesce(invoice.istransferredtoacc, 0) = 0
    	--and invoice.visittype='outpatient'
    	) innertable
    group by 
    	innertable.organizationid
    	,invoiceid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;