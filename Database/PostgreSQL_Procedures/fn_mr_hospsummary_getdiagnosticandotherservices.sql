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
BEGIN
    RETURN QUERY
    SELECT 
        fTable.ReportingItemName::VARCHAR,
        'Number'::VARCHAR AS Unit,
        COUNT(CASE WHEN fTable.BillingTransactionId IS NOT NULL THEN fTable.BillingTransactionId END)::INT AS TotalCount,
        0::INT AS OrderPriority
    FROM (
        SELECT 
            rpLjt.ReportingItemName,
            txnTable.BillingTransactionId,
            txnTable.Gender
        FROM (
            SELECT 
                rpim.ServiceItemId,
                rptTable.ReportingItemName,
                bp.ServiceDepartmentId,
                bp.IntegrationItemId
            FROM (
                SELECT ReportingItemsId, ReportingItemName
                FROM mst_rpt_dynamicreportingitems
                WHERE IsActive = TRUE
                  AND DynamicReportId = (
                      SELECT DynamicReportId
                      FROM mst_rpt_dynamicreportname
                      WHERE ReportCode = 'RPT_DiagnosticAndOtherServices'
                  )
                  AND LOWER(RptCountUnit) = 'number'
            ) AS rptTable
            LEFT JOIN bil_map_reportingitem_billingitems rpim ON rpim.ReportingItemsId = rptTable.ReportingItemsId
            LEFT JOIN bil_mst_serviceitem bp ON bp.ServiceItemId = rpim.ServiceItemId
        ) AS rpLjt
        LEFT JOIN (
            SELECT 
                btxi.BillingTransactionId,
                btxi.ServiceDepartmentId,
                btxi.IntegrationItemId,
                pat.Gender
            FROM bil_txn_billingtransactionitems btxi
            INNER JOIN bil_txn_billingtransaction inv ON btxi.BillingTransactionId = inv.BillingTransactionId
            INNER JOIN pat_patient pat ON pat.PatientId = btxi.PatientId
            LEFT JOIN bil_txn_invoicereturnitems brtn ON btxi.BillingTransactionItemId = brtn.BillingTransactionItemId
            WHERE btxi.BillStatus != 'cancel'
              AND btxi.BillStatus != 'adtCancel'
              AND btxi.BillStatus != 'provisional'
              AND brtn.BillReturnItemId IS NULL
              AND inv.CreatedOn::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt.IntegrationItemId = txnTable.IntegrationItemId
          AND rpLjt.ServiceDepartmentId = txnTable.ServiceDepartmentId
    ) AS fTable
    GROUP BY fTable.ReportingItemName

    UNION ALL

    SELECT 
        fTable.ReportingItemName::VARCHAR,
        'Person'::VARCHAR AS Unit,
        COUNT(CASE WHEN fTable.PatientId IS NOT NULL THEN fTable.PatientId END)::INT AS TotalCount,
        1::INT AS OrderPriority
    FROM (
        SELECT 
            rpLjt.ReportingItemName,
            txnTable.PatientId,
            txnTable.Gender,
            txnTable.ServiceDepartmentId,
            txnTable.IntegrationItemId
        FROM (
            SELECT 
                rpim.ServiceItemId,
                rptTable.ReportingItemName,
                bp.ServiceDepartmentId,
                bp.IntegrationItemId
            FROM (
                SELECT ReportingItemsId, ReportingItemName
                FROM mst_rpt_dynamicreportingitems
                WHERE IsActive = TRUE
                  AND DynamicReportId = (
                      SELECT DynamicReportId
                      FROM mst_rpt_dynamicreportname
                      WHERE ReportCode = 'RPT_DiagnosticAndOtherServices'
                  )
                  AND LOWER(RptCountUnit) = 'person'
            ) AS rptTable
            LEFT JOIN bil_map_reportingitem_billingitems rpim ON rpim.ReportingItemsId = rptTable.ReportingItemsId
            LEFT JOIN bil_mst_serviceitem bp ON bp.ServiceItemId = rpim.ServiceItemId
        ) AS rpLjt
        LEFT JOIN (
            SELECT DISTINCT 
                btxi.ServiceDepartmentId,
                btxi.IntegrationItemId,
                pat.Gender,
                pat.PatientId
            FROM bil_txn_billingtransactionitems btxi
            INNER JOIN pat_patient pat ON pat.PatientId = btxi.PatientId
            INNER JOIN bil_txn_billingtransaction inv ON btxi.BillingTransactionId = inv.BillingTransactionId
            LEFT JOIN bil_txn_invoicereturnitems brtn ON btxi.BillingTransactionItemId = brtn.BillingTransactionItemId
            WHERE btxi.BillStatus != 'cancel'
              AND btxi.BillStatus != 'adtCancel'
              AND btxi.BillStatus != 'provisional'
              AND brtn.BillReturnItemId IS NULL
              AND inv.CreatedOn::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt.IntegrationItemId = txnTable.IntegrationItemId
          AND rpLjt.ServiceDepartmentId = txnTable.ServiceDepartmentId
    ) AS fTable
    GROUP BY fTable.ReportingItemName;
END;
$$;
