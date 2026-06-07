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
BEGIN
    RETURN QUERY
    SELECT 
        fTable.ReportingItemName::VARCHAR,
        COUNT(CASE WHEN fTable.Gender = 'Male' THEN 1 END)::INT AS MaleCount,
        COUNT(CASE WHEN fTable.Gender = 'Female' THEN 1 END)::INT AS FemaleCount
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
                      WHERE ReportCode = 'RPT_FreeServiceToImpoverishedCitizen'
                  )
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
            INNER JOIN pat_patient pat ON pat.PatientId = btxi.PatientId
            INNER JOIN bil_txn_billingtransaction inv ON btxi.BillingTransactionId = inv.BillingTransactionId
            LEFT JOIN bil_txn_invoicereturnitems brtn ON btxi.BillingTransactionItemId = brtn.BillingTransactionItemId
            WHERE COALESCE(btxi.DiscountAmount, 0) / COALESCE(NULLIF(btxi.SubTotal, 0), 1) * 100 = 100
              AND brtn.BillReturnItemId IS NULL
              AND inv.CreatedOn::DATE BETWEEN p_fromdate AND p_todate
        ) AS txnTable ON rpLjt.IntegrationItemId = txnTable.IntegrationItemId
          AND rpLjt.ServiceDepartmentId = txnTable.ServiceDepartmentId
    ) AS fTable
    GROUP BY fTable.ReportingItemName;
END;
$$;
