CREATE OR REPLACE FUNCTION sp_utl_schemerefundtransactions(
    p_fromdate timestamp,
    p_todate timestamp
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT 
        txn."CreatedOn" AS "RefundDate",
        txn."ReceiptNo" AS "ReceiptNo",
        sch."SchemeName" AS "SchemeName",
        pat."PatientCode" AS "HospitalNumber",
        pat."ShortName" AS "PatientName",
        CONCAT(pat."Age", '/', pat."Gender") AS "Age",
        txn."InpatientNumber" AS "InpatientNumber",
        txn."RefundAmount" AS "RefundAmount",
        emp."FullName" AS "EnteredBy",
        txn."Remarks" AS "Remarks"
    FROM "BIL_TXN_SchemeRefund" txn
    INNER JOIN "PAT_Patient" pat ON txn."PatientId" = pat."PatientId"
    INNER JOIN "BIL_CFG_Scheme" sch ON txn."SchemeId" = sch."SchemeId"
    LEFT JOIN "EMP_Employee" emp ON txn."CreatedBy" = emp."EmployeeId"
    WHERE txn."IsActive" = true
      AND txn."CreatedOn" >= p_fromdate
      AND txn."CreatedOn" <= p_todate;
      
    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
