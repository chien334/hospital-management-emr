CREATE OR REPLACE FUNCTION sp_acc_post_phrm_credit_getcreditorganizationsalesreturn(
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
     exec sp_acc_post_phrm_credit_getcreditorganizationsalesreturn '2023-06-19',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/19th june 23                initial draft of sp to get pharmacy outpatient credit sales return detail(credit organization).
    */
    
    RETURN QUERY SELECT 
    	'PHRM_OPD_CREDIT_Sale_Return' AS "TransactionType"
    	,coalesce(ledgerid,0) AS "LedgerId"
    	,coalesce(subledgerid,0) AS "SubLedgerId"
    	,sum(totalamount) AS "TotalAmount"
    	,string_agg(referenceid, ',') AS "ReferenceIdCSV"
    	,transactiondate AS "TransactionDate"
    	,description
    	,1 AS "DisplaySequence"
    	,0 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoicereturnid as referenceid
    		,retinvoice.returncreditamount AS "TotalAmount"
    		,cast(retinvoice.createdon as date) AS "TransactionDate"
    		,(patient.patientcode)::varchar || '-' || patient.shortname || '-CLAIMCODE-'|| (coalesce(retinvoice.claimcode,''))::varchar || '-' || (cast(retinvoice.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    		,retinvoice.organizationid
    		,retinvoice.invoicereturnid
    	from phrm_txn_invoicereturn retinvoice
    	join acc_ledger_mapping map on map.referenceid = retinvoice.organizationid
    	join bil_cfg_fiscalyears fy  on retinvoice.fiscalyearid = fy.fiscalyearid  
    	join pat_patient patient on retinvoice.patientid = patient.patientid
    	join bil_mst_credit_organization org on retinvoice.organizationid = org.organizationid
    	where (retinvoice.createdon)::date = p_transactiondate
    	and retinvoice.paymentmode = 'credit'
    	and map.ledgertype = 'creditorganization'
    	and org.creditorganizationcode <> 'MEDICARE'
    	and coalesce(retinvoice.istransferredtoacc, 0) = 0
    	--and retinvoice.visittype='outpatient'
    	) innertable
    group by 
    	innertable.organizationid
    	,invoicereturnid
    	,ledgerid
    	,subledgerid
    	,transactiondate
    	,description;
END;
$$ LANGUAGE plpgsql;