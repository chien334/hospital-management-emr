DROP FUNCTION IF EXISTS sp_report_radiology_revenuegenerated(date, date);
DROP FUNCTION IF EXISTS sp_report_radiology_revenuegenerated(timestamp without time zone, timestamp without time zone);

CREATE OR REPLACE FUNCTION sp_report_radiology_revenuegenerated(
    p_fromdate timestamp,
    p_todate timestamp
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT 
        (d."PaidDate")::date AS "Date",
        SUM(d."Price") AS "TotalPrice",
        SUM(d."TotalAmount") AS "TotalPaidAmount",
        SUM(d."Tax") AS "TotalTax"
    FROM "BIL_MST_ServiceDepartment" t
    INNER JOIN "BIL_TXN_BillingTransactionItems" d ON d."ServiceDepartmentName" = t."ServiceDepartmentName"
    WHERE (d."PaidDate")::date BETWEEN p_fromdate::date AND p_todate::date 
      AND t."DepartmentId" = (SELECT "DepartmentId" FROM "MST_Department" WHERE "DepartmentName" = 'Radiology' LIMIT 1)
    GROUP BY (d."PaidDate")::date;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;