CREATE OR REPLACE FUNCTION sp_acc_post_phrm_credit_getinternalcreditorganizationsalesreturn(
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
     exec sp_acc_post_phrm_credit_getinternalcreditorganizationsalesreturn '2023-06-19',1
     change history
    sn.                auther/timestamp                   description
    1.                 devn/19th june 23                initial draft of sp to get opd (credit) pharmacy sales return (medicare).
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
    	,0 AS "DrCr"
    	,'PHRM_Income_Voucher' AS "BaseTransactionType"
    	,1 AS "TransactionRefNo"
    from (
    	select 
    		invoicereturnid as referenceid
    		,'PHRM_OPD_CREDIT_Sales_Return' AS "TransactionType"
    		,retinvoice.returncreditamount AS "TotalAmount"
    		,cast(retinvoice.createdon as date) AS "TransactionDate"
    		,'OP SALE Return (STAFF MEDICARE) Cedit Note Ref. No.(CR-PH-' || (retinvoice.creditnoteid)::varchar  || ') for ' || (cast(retinvoice.createdon as date))::varchar AS "Description"
    		,map.ledgerid AS "LedgerId"
    		,map.subledgerid AS "SubLedgerId"
    	from phrm_txn_invoicereturn retinvoice
    	join ins_medicaremember patient on retinvoice.patientid = patient.patientid
    	join acc_ledger_mapping map on map.referenceid = patient.medicarememberid
    	join bil_mst_credit_organization org on retinvoice.organizationid = org.organizationid
    	where (retinvoice.createdon)::date = p_transactiondate
    	and retinvoice.paymentmode = 'credit' 
    	and coalesce(retinvoice.istransferredtoacc, 0) = 0
    	and retinvoice.paymentmode = 'credit'
    	and map.ledgertype = 'MedicareMember'
    	and org.creditorganizationcode = 'MEDICARE'
    	) innertable
    group by innertable.ledgerid
    	,innertable.referenceid
    	,innertable.subledgerid
    	,transactiondate
    	,description
    	,transactiontype;
END;
$$ LANGUAGE plpgsql;