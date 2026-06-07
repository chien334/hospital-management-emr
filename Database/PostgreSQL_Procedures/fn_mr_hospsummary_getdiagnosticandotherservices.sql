DROP FUNCTION IF EXISTS public.fn_mr_hospsummary_getdiagnosticandotherservices(DATE, DATE) CASCADE;

CREATE OR REPLACE FUNCTION public.fn_mr_hospsummary_getdiagnosticandotherservices(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "ReportingItemName" VARCHAR,
    "Unit" VARCHAR,
    "TotalCount" INT,
    "OrderPriority" INT
)
LANGUAGE plpgsql
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT 
        fTable."ReportingItemName"::VARCHAR,
        'Number'::VARCHAR AS "Unit",
        COUNT(CASE WHEN fTable."BillingTransactionId" IS NOT NULL THEN fTable."BillingTransactionId" END)::INT AS "TotalCount",
        0::INT AS "OrderPriority"
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
                      WHERE "ReportCode" = 'RPT_DiagnosticAndOtherServices'
                  )
                  AND LOWER("RptCountUnit") = 'number'
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
            INNER JOIN "BIL_TXN_BillingTransaction" inv ON btxi."BillingTransactionId" = inv."BillingTransactionId"
            INNER JOIN "PAT_Patient" pat ON pat."PatientId" = btxi."PatientId"
            LEFT JOIN "BIL_TXN_InvoiceReturnItems" brtn ON btxi."BillingTransactionItemId" = brtn."BillingTransactionItemId"
            WHERE btxi."BillStatus" != 'cancel'
              AND btxi."BillStatus" != 'adtCancel'
              AND btxi."BillStatus" != 'provisional'
              AND brtn."BillReturnItemId" IS NULL
              AND inv."CreatedOn"::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt."IntegrationItemId" = txnTable."IntegrationItemId"
          AND rpLjt."ServiceDepartmentId" = txnTable."ServiceDepartmentId"
    ) AS fTable
    GROUP BY fTable."ReportingItemName"

    UNION ALL

    SELECT 
        fTable."ReportingItemName"::VARCHAR,
        'Person'::VARCHAR AS "Unit",
        COUNT(CASE WHEN fTable."PatientId" IS NOT NULL THEN fTable."PatientId" END)::INT AS "TotalCount",
        1::INT AS "OrderPriority"
    FROM (
        SELECT 
            rpLjt."ReportingItemName",
            txnTable."PatientId",
            txnTable."Gender",
            txnTable."ServiceDepartmentId",
            txnTable."IntegrationItemId"
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
                      WHERE "ReportCode" = 'RPT_DiagnosticAndOtherServices'
                  )
                  AND LOWER("RptCountUnit") = 'person'
            ) AS rptTable
            LEFT JOIN "BIL_MAP_ReportingItem_BillingItems" rpim ON rpim."ReportingItemsId" = rptTable."ReportingItemsId"
            LEFT JOIN "BIL_MST_ServiceItem" bp ON bp."ServiceItemId" = rpim."ServiceItemId"
        ) AS rpLjt
        LEFT JOIN (
            SELECT DISTINCT 
                btxi."ServiceDepartmentId",
                btxi."IntegrationItemId",
                pat."Gender",
                pat."PatientId"
            FROM "BIL_TXN_BillingTransactionItems" btxi
            INNER JOIN "PAT_Patient" pat ON pat."PatientId" = btxi."PatientId"
            INNER JOIN "BIL_TXN_BillingTransaction" inv ON btxi."BillingTransactionId" = inv."BillingTransactionId"
            LEFT JOIN "BIL_TXN_InvoiceReturnItems" brtn ON btxi."BillingTransactionItemId" = brtn."BillingTransactionItemId"
            WHERE btxi."BillStatus" != 'cancel'
              AND btxi."BillStatus" != 'adtCancel'
              AND btxi."BillStatus" != 'provisional'
              AND brtn."BillReturnItemId" IS NULL
              AND inv."CreatedOn"::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt."IntegrationItemId" = txnTable."IntegrationItemId"
          AND rpLjt."ServiceDepartmentId" = txnTable."ServiceDepartmentId"
    ) AS fTable
    GROUP BY fTable."ReportingItemName";
END;
$$;
