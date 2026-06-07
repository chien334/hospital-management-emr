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
     description: to get transaction invoices details on invoice level
     remarks: needs revision.
     change history:
     s.no.    changedate/by       remarks
     1.      24jan'20/Pratik          Initial Draft (Needs Revision)
     
    */
    
    RETURN QUERY SELECT
        pat."PatientId"::INT, 
        (pat."FirstName" || ' ' || COALESCE(pat."MiddleName" || ' ', '') || pat."LastName")::VARCHAR AS "PatientName", 
        pat."PatientCode"::VARCHAR,
        (fyear."FiscalYearFormatted" || '-' || biltxn."InvoiceCode" || CAST(biltxn."InvoiceNo" AS VARCHAR(20)))::VARCHAR AS "InvoiceNo", 
        biltxn."CreatedOn"::TIMESTAMP AS "TransactionDate", 
        biltxn."TotalAmount"::DECIMAL, 
        biltxn."BillingTransactionId"::INT
    FROM "BIL_TXN_BillingTransaction" AS biltxn
    JOIN "BIL_CFG_FiscalYears" AS fyear ON biltxn."FiscalYearId" = fyear."FiscalYearId"
    JOIN "PAT_Patient" AS pat ON biltxn."PatientId" = pat."PatientId"
    WHERE (biltxn."CreatedOn")::DATE BETWEEN (p_fromdate)::DATE AND (p_todate)::DATE
      AND COALESCE(biltxn."ReturnStatus", FALSE) = FALSE;
END;
$$ LANGUAGE plpgsql;