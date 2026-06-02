CREATE OR REPLACE FUNCTION sp_bil_getbilltxnitemsbetndaterange_fordepartment(
    p_fromdate text DEFAULT NULL,
    p_todate text DEFAULT NULL,
    p_searchtext text DEFAULT NULL,
    p_srvdptintegrationname text DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
    v_fromdate date;
    v_todate date;
    v_searchtext text := COALESCE(p_searchtext, '');
    v_integrationname text := COALESCE(p_srvdptintegrationname, '');
BEGIN
    IF p_fromdate IS NOT NULL AND p_fromdate <> '' THEN
        v_fromdate := p_fromdate::date;
    ELSE
        v_fromdate := CURRENT_DATE;
    END IF;

    IF p_todate IS NOT NULL AND p_todate <> '' THEN
        v_todate := p_todate::date;
    ELSE
        v_todate := CURRENT_DATE;
    END IF;

    OPEN ref FOR
    SELECT 
        txnItem."CreatedOn" as "Date",
        txnItem."ServiceDepartmentId",
        txnItem."ServiceDepartmentName",
        txnItem."ItemId",
        txnItem."ItemName",
        txnItem."PerformerId",
        txnItem."PerformerName",
        txnItem."BillingTransactionItemId",
        txnItem."BillStatus",
        txnItem."PrescriberId" as "PrescriberId",
        txnItem."BillingTransactionId",
        txnItem."RequisitionId",
        COALESCE(bilTxn."InvoiceCode", '') || COALESCE(bilTxn."InvoiceNo"::text, '') as "ReceiptNo",
        pat."PatientId",
        pat."ShortName" as "PatientName",
        pat."DateOfBirth",
        pat."Gender",
        pat."PhoneNumber",
        pat."PatientCode",
        cfg."IsDoctorMandatory" as "DoctorMandatory",
        emp."FullName" as "PrescriberName"
    FROM "BIL_TXN_BillingTransactionItems" txnItem
    INNER JOIN "BIL_MST_ServiceDepartment" srv ON srv."ServiceDepartmentId" = txnItem."ServiceDepartmentId" 
    INNER JOIN "PAT_Patient" pat ON txnItem."PatientId" = pat."PatientId"
    INNER JOIN "BIL_MST_ServiceItem" cfg ON txnItem."ServiceDepartmentId" = cfg."ServiceDepartmentId" AND txnItem."ItemId" = cfg."IntegrationItemId"
    LEFT JOIN "BIL_TXN_BillingTransaction" bilTxn ON txnItem."BillingTransactionId" = bilTxn."BillingTransactionId"
    LEFT JOIN "EMP_Employee" emp ON txnItem."PrescriberId" = emp."EmployeeId"
    WHERE 
        COALESCE(srv."IntegrationName", '') ILIKE '%' || v_integrationname || '%'
        AND txnItem."BillStatus" <> 'cancel'
        AND txnItem."BillStatus" <> 'adtCancel'
        AND txnItem."ReturnStatus" IS DISTINCT FROM TRUE
        AND txnItem."CreatedOn"::date BETWEEN v_fromdate AND v_todate
        AND (
            pat."ShortName" || pat."PatientCode" || COALESCE(pat."PhoneNumber", '') || srv."ServiceDepartmentName" || txnItem."ItemName"
        ) ILIKE '%' || v_searchtext || '%'
    ORDER BY txnItem."BillingTransactionItemId" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
