CREATE OR REPLACE FUNCTION sp_inctv_viewtxn_invoicelevel(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_employeeid INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "InvoiceNo" VARCHAR,
    "TransactionDate" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "BillingTransactionId" INT
) AS $$
BEGIN
    /*
     file: sp_inctv_viewtxn_invoicelevel
     description: 
     conditions/checks: 
            
    
     remarks: needs revision.
     change history:
     s.no.    changedate/by       remarks
     1.      24jan'20/Pratik          Initial Draft (Needs Revision)
     
    */
    
    
    RETURN QUERY SELECT
    pat.PatientId, pat.FirstName||' '||COALESCE(pat.MiddleName||' ','')||pat.LastName AS "PatientName", pat.PatientCode,
    
     fyear.FiscalYearFormatted ||'-'|| biltxn.invoicecode || cast(biltxn.invoiceno as varchar(20)) AS "InvoiceNo" 
    , biltxn.createdon AS "TransactionDate", biltxn.totalamount, biltxn.billingtransactionid
    
    from bil_txn_billingtransaction biltxn, bil_cfg_fiscalyears fyear, pat_patient pat
    where 
    	biltxn.fiscalyearid=fyear.fiscalyearid 
    	and biltxn.patientid=pat.patientid
    	and (biltxn.createdon)::date between p_fromdate and p_todate
    	and coalesce(biltxn.returnstatus,0) = 0;
END;
$$ LANGUAGE plpgsql;