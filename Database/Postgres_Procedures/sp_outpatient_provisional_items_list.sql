CREATE OR REPLACE FUNCTION sp_outpatient_provisional_items_list(
    p_fromdate text DEFAULT NULL,
    p_todate text DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
    v_fromdate date;
    v_todate date;
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
    SELECT pat."ShortName", pat."Age", pat."Gender", pat."DateOfBirth", pat."PatientCode", srv."IntegrationName",
           item.*
    FROM "BIL_TXN_BillingTransactionItems" item
    JOIN "PAT_Patient" pat ON pat."PatientId" = item."PatientId"
    INNER JOIN "BIL_MST_ServiceDepartment" srv ON srv."ServiceDepartmentId" = item."ServiceDepartmentId"
    WHERE LOWER(item."VisitType") = 'outpatient' 
      AND LOWER(item."BillStatus") = 'provisional' 
      AND item."CreatedOn"::date BETWEEN v_fromdate AND v_todate
    ORDER BY item."CreatedOn" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
