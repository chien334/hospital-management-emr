CREATE OR REPLACE FUNCTION sp_bil_dashboard_cardsummary(
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    v_fromdateforweekly DATE;
    v_todateforweekly DATE;
BEGIN
    v_fromdateforweekly := DATE_TRUNC('week', CURRENT_TIMESTAMP)::DATE;
    v_todateforweekly := CURRENT_TIMESTAMP::DATE;

    -- table1: PatientReport
    OPEN ref1 FOR
    SELECT
        COALESCE(SUM(CASE WHEN Period = 'Total_Today' THEN TotalPatientsCount ELSE 0 END), 0) AS "Total_Today",
        COALESCE(SUM(CASE WHEN Period = 'Total_Weekly' THEN TotalPatientsCount ELSE 0 END), 0) AS "Total_Weekly",
        COALESCE(SUM(CASE WHEN Period = 'Total_Monthly' THEN TotalPatientsCount ELSE 0 END), 0) AS "Total_Monthly"
    FROM (
        SELECT 
            'Total_Today' AS Period,
            COUNT(COALESCE(txn.BillingTransactionId,0)) AS TotalPatientsCount
        FROM BIL_TXN_BillingTransaction txn
        INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
        LEFT JOIN PAT_PatientVisits visit ON visit.ParentVisitId = txn.PatientVisitId
        WHERE txn.CreatedOn::DATE = CURRENT_TIMESTAMP::DATE
        
        UNION ALL
        
        SELECT 
            'Total_Weekly' AS Period,
            COUNT(COALESCE(txn.BillingTransactionId,0)) AS TotalPatientsCount
        FROM BIL_TXN_BillingTransaction txn
        INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
        LEFT JOIN PAT_PatientVisits visit ON visit.ParentVisitId = txn.PatientVisitId
        WHERE txn.CreatedOn::DATE BETWEEN v_fromdateforweekly AND v_todateforweekly
        
        UNION ALL
        
        SELECT 
            'Total_Monthly' AS Period,
            COUNT(COALESCE(txn.BillingTransactionId,0)) AS TotalPatientsCount
        FROM BIL_TXN_BillingTransaction txn
        INNER JOIN PAT_Patient pat ON txn.PatientId = pat.PatientId
        LEFT JOIN PAT_PatientVisits visit ON visit.ParentVisitId = txn.PatientVisitId
        WHERE EXTRACT(YEAR FROM txn.CreatedOn) = EXTRACT(YEAR FROM CURRENT_TIMESTAMP) 
          AND EXTRACT(MONTH FROM txn.CreatedOn) = EXTRACT(MONTH FROM CURRENT_TIMESTAMP)
    ) tbl;
    RETURN NEXT ref1;

    -- table2: IncomeReport
    OPEN ref2 FOR
    SELECT
        COALESCE(SUM(CASE WHEN Period = 'Total_Today' THEN TotalIncome ELSE 0 END), 0) AS "Total_Today",
        COALESCE(SUM(CASE WHEN Period = 'Total_Weekly' THEN TotalIncome ELSE 0 END), 0) AS "Total_Weekly",
        COALESCE(SUM(CASE WHEN Period = 'Total_Monthly' THEN TotalIncome ELSE 0 END), 0) AS "Total_Monthly"
    FROM (
        SELECT 
            'Total_Today' AS Period,
            COALESCE((SUM(COALESCE(InAmount,0)) - SUM(COALESCE(OutAmount, 0))),0) AS TotalIncome
        FROM TXN_EmpCashTransaction
        WHERE TransactionDate::DATE = CURRENT_TIMESTAMP::DATE
        
        UNION ALL
        
        SELECT 
            'Total_Weekly' AS Period,
            COALESCE((SUM(COALESCE(InAmount,0)) - SUM(COALESCE(OutAmount, 0))),0) AS TotalIncome
        FROM TXN_EmpCashTransaction
        WHERE TransactionDate::DATE BETWEEN v_fromdateforweekly AND v_todateforweekly
        
        UNION ALL
        
        SELECT 
            'Total_Monthly' AS Period,
            COALESCE((SUM(COALESCE(InAmount,0)) - SUM(COALESCE(OutAmount, 0))),0) AS TotalIncome
        FROM TXN_EmpCashTransaction
        WHERE EXTRACT(YEAR FROM TransactionDate) = EXTRACT(YEAR FROM CURRENT_TIMESTAMP) 
          AND EXTRACT(MONTH FROM TransactionDate) = EXTRACT(MONTH FROM CURRENT_TIMESTAMP)
    ) tbl;
    RETURN NEXT ref2;

    -- table3: BillReturnReport
    OPEN ref3 FOR
    SELECT
        COALESCE(SUM(CASE WHEN Period = 'Total_Today' THEN TotalBillsReturnCount ELSE 0 END), 0) AS "Total_Today",
        COALESCE(SUM(CASE WHEN Period = 'Total_Weekly' THEN TotalBillsReturnCount ELSE 0 END), 0) AS "Total_Weekly",
        COALESCE(SUM(CASE WHEN Period = 'Total_Monthly' THEN TotalBillsReturnCount ELSE 0 END), 0) AS "Total_Monthly"
    FROM (
        SELECT 
            'Total_Today' AS Period,
            COUNT(ret.BillReturnId) AS TotalBillsReturnCount
        FROM BIL_TXN_InvoiceReturn ret
        INNER JOIN PAT_Patient pat ON ret.PatientId = pat.PatientId
        WHERE ret.CreatedOn::DATE = CURRENT_TIMESTAMP::DATE
        
        UNION ALL
        
        SELECT 
            'Total_Weekly' AS Period,
            COUNT(ret.BillReturnId) AS TotalBillsReturnCount
        FROM BIL_TXN_InvoiceReturn ret
        INNER JOIN PAT_Patient pat ON ret.PatientId = pat.PatientId
        WHERE ret.CreatedOn::DATE BETWEEN v_fromdateforweekly AND v_todateforweekly
        
        UNION ALL
        
        SELECT 
            'Total_Monthly' AS Period,
            COUNT(ret.BillReturnId) AS TotalBillsReturnCount
        FROM BIL_TXN_InvoiceReturn ret
        INNER JOIN PAT_Patient pat ON ret.PatientId = pat.PatientId
        WHERE EXTRACT(YEAR FROM ret.CreatedOn) = EXTRACT(YEAR FROM CURRENT_TIMESTAMP) 
          AND EXTRACT(MONTH FROM ret.CreatedOn) = EXTRACT(MONTH FROM CURRENT_TIMESTAMP)
    ) tbl;
    RETURN NEXT ref3;

END;
$$ LANGUAGE plpgsql;