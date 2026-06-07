DROP FUNCTION IF EXISTS public.fn_mr_hospsummary_getfreeservices(DATE, DATE) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_mr_hospsummary_getfreeservices(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "ReportingItemName" VARCHAR,
    "MaleCount" INT,
    "FemaleCount" INT
)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT 
        fTable."ReportingItemName"::VARCHAR,
        COUNT(CASE WHEN fTable."Gender" = 'Male' THEN 1 END)::INT AS "MaleCount",
        COUNT(CASE WHEN fTable."Gender" = 'Female' THEN 1 END)::INT AS "FemaleCount"
    FROM (
        SELECT 
            rpLjt."ReportingItemName",
            txnTable."BillingTransactionId",
            txnTable."Gender"
        FROM (
            SELECT 
                rpim."ServiceItemId",
                rptTable."ReportingItemName",
                bp."ServiceDepartmentId",
                bp."IntegrationItemId"
            FROM (
                SELECT "ReportingItemsId", "ReportingItemName"
                FROM "MST_RPT_DynamicReportingItems"
                WHERE "IsActive" = TRUE
                  AND "DynamicReportId" = (
                      SELECT "DynamicReportId"
                      FROM "MST_RPT_DynamicReportName"
                      WHERE "ReportCode" = 'RPT_FreeServiceToImpoverishedCitizen'
                  )
            ) AS rptTable
            LEFT JOIN "BIL_MAP_ReportingItem_BillingItems" rpim ON rpim."ReportingItemsId" = rptTable."ReportingItemsId"
            LEFT JOIN "BIL_MST_ServiceItem" bp ON bp."ServiceItemId" = rpim."ServiceItemId"
        ) AS rpLjt
        LEFT JOIN (
            SELECT 
                btxi."BillingTransactionId",
                btxi."ServiceDepartmentId",
                btxi."IntegrationItemId",
                pat."Gender"
            FROM "BIL_TXN_BillingTransactionItems" btxi
            INNER JOIN "PAT_Patient" pat ON pat."PatientId" = btxi."PatientId"
            INNER JOIN "BIL_TXN_BillingTransaction" inv ON btxi."BillingTransactionId" = inv."BillingTransactionId"
            LEFT JOIN "BIL_TXN_InvoiceReturnItems" brtn ON btxi."BillingTransactionItemId" = brtn."BillingTransactionItemId"
            WHERE COALESCE(btxi."DiscountAmount", 0) / COALESCE(NULLIF(btxi."SubTotal", 0), 1) * 100 = 100
              AND brtn."BillReturnItemId" IS NULL
              AND inv."CreatedOn"::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt."IntegrationItemId" = txnTable."IntegrationItemId"
          AND rpLjt."ServiceDepartmentId" = txnTable."ServiceDepartmentId"
    ) AS fTable
    GROUP BY fTable."ReportingItemName";
END;
$$;
